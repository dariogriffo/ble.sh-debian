BLESH_VERSION=$1
BUILD_VERSION=$2

if [ -z "$BLESH_VERSION" ] || [ -z "$BUILD_VERSION" ]; then
    echo "Usage: $0 <blesh_version> <build_version>"
    echo "Example: $0 0.4.0-git20260908.d81fd54 1"
    exit 1
fi

# ble.sh is written in pure Bash, so a single Architecture: all package covers
# every Debian architecture (amd64, arm64, armel, armhf, i386, ppc64el,
# riscv64, s390x, ...).
ARCH="all"
BLESH_SRC="blesh"

# Our version is 0.4.0-git<date>.<sha>; upstream publishes that snapshot as
# ble-nightly-<date>+<sha>.tar.xz on its rolling "nightly" release.
SNAPSHOT="${BLESH_VERSION##*-git}"
NIGHTLY="ble-nightly-${SNAPSHOT%%.*}+${SNAPSHOT#*.}"

download_upstream() {
    # Clean up any previous download
    rm -rf "$BLESH_SRC" || true
    rm -f "${NIGHTLY}.tar.xz" || true

    # The nightly tarball is the already-generated install tree (ble.sh, lib/,
    # contrib/, doc/, licenses/) -- everything the packages install.
    if ! wget "https://github.com/akinomyoga/ble.sh/releases/download/nightly/${NIGHTLY/+/%2B}.tar.xz" -O "${NIGHTLY}.tar.xz"; then
        echo "❌ Failed to download ble.sh $BLESH_VERSION"
        return 1
    fi

    if ! tar -xf "${NIGHTLY}.tar.xz"; then
        echo "❌ Failed to extract ble.sh $BLESH_VERSION"
        return 1
    fi

    if [ ! -f "${NIGHTLY}/ble.sh" ] || [ ! -d "${NIGHTLY}/contrib/airline" ]; then
        echo "❌ Unexpected tarball layout for ble.sh $BLESH_VERSION"
        return 1
    fi

    mv "$NIGHTLY" "$BLESH_SRC"
    rm -f "${NIGHTLY}.tar.xz"
    return 0
}

build_packages() {
    echo "Building for architecture: $ARCH"

    if ! download_upstream; then
        return 1
    fi

    declare -a arr=("bookworm" "trixie" "forky" "sid")

    for dist in "${arr[@]}"; do
        FULL_VERSION="$BLESH_VERSION-${BUILD_VERSION}~${dist}_${ARCH}"
        echo "  Building $FULL_VERSION"

        if ! docker build . -t "blesh-$dist-$ARCH" \
            --build-arg DEBIAN_DIST="$dist" \
            --build-arg BLESH_VERSION="$BLESH_VERSION" \
            --build-arg BUILD_VERSION="$BUILD_VERSION" \
            --build-arg FULL_VERSION="$FULL_VERSION" \
            --build-arg ARCH="$ARCH" \
            --build-arg BLESH_SRC="$BLESH_SRC"; then
            echo "❌ Failed to build Docker image for $dist"
            return 1
        fi

        id="$(docker create "blesh-$dist-$ARCH")"
        for pkg in ble.sh ble.sh-airline-themes; do
            if ! docker cp "$id:/${pkg}_$FULL_VERSION.deb" - > "./${pkg}_$FULL_VERSION.deb"; then
                echo "❌ Failed to extract $pkg .deb package for $dist"
                return 1
            fi

            if ! tar -xf "./${pkg}_$FULL_VERSION.deb"; then
                echo "❌ Failed to extract $pkg .deb contents for $dist"
                return 1
            fi
        done
    done

    # Clean up extracted directory
    rm -rf "$BLESH_SRC" || true

    echo "✅ Successfully built for $ARCH"
    return 0
}

echo "🚀 Building ble.sh $BLESH_VERSION-$BUILD_VERSION for Debian..."
echo ""

if ! build_packages; then
    exit 1
fi

echo ""
echo "🎉 Debian packages built successfully!"
echo "Generated packages:"
ls -la ble.sh*~{bookworm,trixie,forky,sid}_all.deb

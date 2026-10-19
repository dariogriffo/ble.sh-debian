#!/bin/bash
set -euo pipefail

BLESH_VERSION=$1
BUILD_VERSION=$2

if [ -z "$BLESH_VERSION" ] || [ -z "$BUILD_VERSION" ]; then
    echo "Usage: $0 <blesh_version> <build_version>"
    echo "Example: $0 0.4.0-git20260908.d81fd54 1"
    exit 1
fi

PACKAGE_NAME="ble.sh"
ORIG_TARBALL="${PACKAGE_NAME}_${BLESH_VERSION}.orig.tar.xz"
BUILD_DIR="${PACKAGE_NAME}-${BLESH_VERSION}"

echo "Creating the source package for ble.sh ${BLESH_VERSION}-${BUILD_VERSION}..."

# Our version is 0.4.0-git<date>.<sha>; upstream publishes that snapshot as
# ble-nightly-<date>+<sha>.tar.xz on its rolling "nightly" release.
SNAPSHOT="${BLESH_VERSION##*-git}"
NIGHTLY="ble-nightly-${SNAPSHOT%%.*}+${SNAPSHOT#*.}"

# A rebuild of an upstream version already released here (a +N build bump)
# must ship the very same orig tarball: the pool holds one per upstream
# version and reprepro refuses a different one, and the repack below is not
# byte-reproducible. Reuse the earlier release's copy.
if [ ! -f "$ORIG_TARBALL" ]; then
    for ((b = BUILD_VERSION - 1; b >= 1; b--)); do
        if wget -q "https://github.com/dariogriffo/ble.sh-debian/releases/download/${BLESH_VERSION}%2B${b}/${ORIG_TARBALL}" -O "$ORIG_TARBALL"; then
            echo "  Reusing $ORIG_TARBALL from release ${BLESH_VERSION}+${b}"
            break
        fi
        rm -f "$ORIG_TARBALL"
    done
fi

# Download the upstream nightly tarball (shared .orig.tar.xz across all
# distributions). It is already the generated install tree, so debian/rules
# never needs network access or upstream's build tools.
# It extracts as ble-nightly-<date>+<sha>/, so repack it as ble.sh-<version>/
# for dpkg-source.
if [ ! -f "$ORIG_TARBALL" ]; then
    echo "Downloading upstream nightly tarball from GitHub..."
    wget -q "https://github.com/akinomyoga/ble.sh/releases/download/nightly/${NIGHTLY/+/%2B}.tar.xz" -O upstream.tar.xz
    rm -rf repack
    mkdir repack
    tar -xf upstream.tar.xz -C repack
    if [ ! -f "repack/${NIGHTLY}/ble.sh" ]; then
        echo "❌ Unexpected tarball layout for ble.sh ${BLESH_VERSION}"
        exit 1
    fi
    mv "repack/${NIGHTLY}" "repack/${BUILD_DIR}"
    tar -cJf "$ORIG_TARBALL" -C repack "$BUILD_DIR"
    rm -rf repack upstream.tar.xz
    echo "  ✅ Created $ORIG_TARBALL"
else
    echo "  ✅ Using existing $ORIG_TARBALL"
fi

build_source_package() {
    local FULL_VERSION="${BLESH_VERSION}-${BUILD_VERSION}~griffo"

    echo "  Building source package ${FULL_VERSION}..."

    # Clean and recreate build directory from orig tarball
    rm -rf "$BUILD_DIR"
    tar -xf "$ORIG_TARBALL"

    # Copy Debian packaging directory
    cp -r debian "$BUILD_DIR/"

    # Generate the changelog (overwrites placeholder)
    cat > "$BUILD_DIR/debian/changelog" << EOF
ble.sh (${FULL_VERSION}) stable; urgency=medium

  * New upstream nightly snapshot ${BLESH_VERSION}.

 -- Dario Griffo <dariogriffo@gmail.com>  $(date -R)
EOF

    # Build source package (.dsc + .debian.tar.xz); reuses existing .orig.tar.xz
    dpkg-source -b "$BUILD_DIR"

    rm -rf "$BUILD_DIR"
    echo "    ✅ ${FULL_VERSION}"
}

echo ""
# One source package for every suite, as with the binaries (see build_debian.sh).
build_source_package

echo ""
echo "🎉 Source packages created successfully!"
echo ""
echo "Generated files:"
ls -la "${PACKAGE_NAME}_"*.dsc "${PACKAGE_NAME}_"*.orig.tar.xz "${PACKAGE_NAME}_"*.debian.tar.xz 2>/dev/null || true

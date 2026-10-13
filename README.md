![GitHub Downloads (all assets, all releases)](https://img.shields.io/github/downloads/dariogriffo/ble.sh-debian/total)
![GitHub Downloads (all assets, latest release)](https://img.shields.io/github/downloads/dariogriffo/ble.sh-debian/latest/total)
![GitHub Release](https://img.shields.io/github/v/release/dariogriffo/ble.sh-debian)
![GitHub Release Date](https://img.shields.io/github/release-date/dariogriffo/ble.sh-debian?display_date=published_at)

<h1>
   <p align="center">
     <a href="https://github.com/akinomyoga/ble.sh"><img src="https://github.com/dariogriffo/ble.sh-debian/blob/main/blesh-logo.svg" alt="ble.sh Logo" width="128" style="margin-right: 20px"></a>
     <a href="https://www.debian.org/"><img src="https://github.com/dariogriffo/ble.sh-debian/blob/main/debian-logo.png" alt="Debian Logo" width="104" style="margin-left: 20px"></a>
     <br>ble.sh for Debian
   </p>
</h1>
<p align="center">
 Bash Line Editor: syntax highlighting, auto suggestions and vim modes for Bash, written in pure Bash.
</p>

# ble.sh for Debian

This repository contains build scripts to produce the _unofficial_ Debian packages
(.deb) for [ble.sh](https://github.com/akinomyoga/ble.sh/) hosted at [deb.griffo.io](https://deb.griffo.io)

Currently supported Debian distros are:
- Bookworm (v12)
- Trixie (v13)
- Forky (v14)
- Sid (testing)

Supported architectures:
- all — ble.sh is written in pure Bash, so a single `Architecture: all`
  package installs on amd64, arm64, armel, armhf, i386, ppc64el, riscv64,
  s390x and every other architecture.

The only dependency is `procps`: ble.sh refuses to load without `ps`, and
minimal Debian images do not ship it. Everything else it needs (bash, awk,
coreutils, sed, grep) is part of every Debian/Ubuntu system.

This is an unofficial community project to provide a package that's easy to
install on Debian. If you're looking for the ble.sh source code, see
[ble.sh](https://github.com/akinomyoga/ble.sh/).

## What's in the packages

The same split Debian uses, with the same package names, so these replace
Debian's own `ble.sh` packages cleanly:

- `ble.sh`
  - `/usr/share/blesh/` — `ble.sh`, `lib/` and `contrib/` from the upstream nightly
  - `/usr/share/doc/ble.sh/` — upstream docs, `README.Debian`, copyright and Debian changelog
  - `ble-update` is redirected to apt
- `ble.sh-airline-themes` (optional)
  - `/usr/share/blesh/contrib/airline/` — the vim-airline themes (MIT)

There is no command in `/usr/bin`, no man page and no shell completions:
ble.sh is a Bash library you source from `~/.bashrc`, and it is itself the
completion engine (it picks up `bash-completion` automatically when present).

## Versions

ble.sh's last stable tag (`v0.4.0-devel3`) is from 2023; upstream recommends,
and Debian packages, the rolling **nightly** build. Packages follow those
snapshots:

```
0.4.0-git<YYYYMMDD>.<commit>     e.g. 0.4.0-git20260908.d81fd54
```

The base (`0.4.0`) is read from upstream's `GNUmakefile` (`FULLVER`). This
sorts above Debian's own `0.4.0~git…` versions.

> **Note:** when upstream eventually ships a stable `0.4.0`, it sorts *below*
> `0.4.0-git…`. Publish it with an epoch (`Version: 1:0.4.0-1~<dist>`) so apt
> upgrades existing installs.

## Install/Update

📖 **Step-by-step install guide:** [Debian](https://deb.griffo.io/install-latest-blesh-in-debian.html) · [Ubuntu](https://deb.griffo.io/install-latest-blesh-in-ubuntu.html)

### The Debian way

> ⚠️ **apt access requires a yearly subscription**
> ([deb.griffo.io](https://deb.griffo.io)). To use this tool for free, download
> the .deb from the [Releases](https://github.com/dariogriffo/ble.sh-debian/releases) page
> and install it manually (see below).

```sh
sudo install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://deb.griffo.io/EA0F721D231FDD3A0A17B9AC7808B4DD62C41256.asc | sudo gpg --dearmor --yes -o /etc/apt/keyrings/deb.griffo.io.gpg
echo "deb [signed-by=/etc/apt/keyrings/deb.griffo.io.gpg] https://deb.griffo.io/apt $(lsb_release -sc 2>/dev/null) main" | sudo tee /etc/apt/sources.list.d/deb.griffo.io.list
sudo apt update
sudo apt install -y ble.sh
# optional: sudo apt install -y ble.sh-airline-themes
```

### Manual Installation

1. Download the .deb package(s) for your Debian version available on
   the [Releases](https://github.com/dariogriffo/ble.sh-debian/releases) page.
2. Install the downloaded .deb package(s).

```sh
sudo dpkg -i <filename>.deb
```

### Enable it

Like Debian's package, nothing is enabled system-wide. Add this near the
**top** of `~/.bashrc`:

```bash
[[ $- == *i* ]] && source /usr/share/blesh/ble.sh --noattach
```

and this at the very **end** of `~/.bashrc`:

```bash
[[ ${BLE_VERSION-} ]] && ble-attach
```

Open a new terminal; `echo $BLE_VERSION` shows the running version.

## Updating

To update to a new version, just follow any of the installation methods above. There's no need to uninstall the old version; it will be updated correctly.

## Building

```sh
./build.sh <blesh_version> <build_version>
# Example: ./build.sh 0.4.0-git20260908.d81fd54 1
```

This builds the Debian binary packages, the Ubuntu binary packages and the
source packages. Each step can also be run on its own:

```sh
./build_debian.sh 0.4.0-git20260908.d81fd54 1
./build_ubuntu.sh 0.4.0-git20260908.d81fd54 1
./build_src.sh    0.4.0-git20260908.d81fd54 1
```

## Roadmap

- [x] Produce a .deb package on GitHub Releases
- [x] Set up a debian mirror for easier updates
- [x] Same package split as Debian (`ble.sh` + `ble.sh-airline-themes`)
- [x] Architecture-independent package covering every architecture

## Disclaimer

- This repo is not open for issues related to ble.sh. This repo is only for _unofficial_ Debian packaging.

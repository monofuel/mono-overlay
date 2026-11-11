# mono-overlay

Custom Gentoo packages, initially for Anbernic handhelds.

## Add the overlay

Clone this repository, then add `/etc/portage/repos.conf/mono-overlay.conf`:

```ini
[mono-overlay]
location = /absolute/path/to/mono-overlay
auto-sync = no
```

Keep the Gentoo repository configured; this overlay inherits its eclasses and
license definitions. Update the checkout explicitly with Git.

## RG DS Plus kernel

On Gentoo ARM64, accept the experimental keyword and build the package:

```sh
mkdir -p /etc/portage/package.accept_keywords
echo 'sys-kernel/rg-ds-plus-rocknix-kernel ~arm64' > /etc/portage/package.accept_keywords/mono-overlay
emerge --ask --buildpkg =sys-kernel/rg-ds-plus-rocknix-kernel-7.0.2
```

This builds Linux 7.0.2 with the ROCKNIX 20261001 RK3566-family patches,
configuration and RG DS Plus device tree. The device has an RK3568; ROCKNIX
groups it with its RK3566 targets. Imports are pinned and stored in this
repository, so building does not fetch a downstream Git checkout.

Artifacts are installed under
`/usr/lib/rg-ds-plus-rocknix-kernel/7.0.2-mono-rgdsplus-rocknix-r0/`:

- `Image`, the ARM64 kernel.
- `rk3568-anbernic-rg-ds-plus.dtb`, the board device tree.
- `config`, `System.map` and `Module.symvers` from the same build.

Matching in-tree modules and dependency indexes are installed under
`/lib/modules/7.0.2-mono-rgdsplus-rocknix-r0/`. Package revisions have their own
kernel release suffix. Different kernel versions can be installed in parallel.
Gentoo's default `UNINSTALL_IGNORE="/lib/modules/*"` preserves modules when a
kernel package is unmerged. This package honors that policy and does not add
a removal hook that deletes retained modules.

**Installing this package does not make the handheld boot it.** It does not
write `/boot`, generate an initramfs, change a bootloader, update
`/usr/src/linux`, or supply firmware. Boot integration and physical device
validation are separate work. Do not replace the working Gentoo card yet.

The package includes in-tree modules, not ROCKNIX's separate Mali module or
proprietary `libmali`. Its configuration retains Panfrost and rtw88 support.
Wi-Fi and speaker-amplifier firmware, regulatory data, userspace control
mapping, audio configuration and the boot chain need separate integration.
The board's separate `rocknix-joypad` controller module is not included.
No prepared external-module build tree is installed.

## RG SP compiled kernel and boot stack

`sys-kernel/rg-sp-rocknix-kernel` builds Linux 7.2 with ROCKNIX's pinned
H700 patches and RG SP board support. Companion packages
`sys-boot/rg-sp-trusted-firmware-a` and `sys-boot/rg-sp-rocknix-u-boot`
build BL31 and both H700 memory variants from source. The first hardware
target is Gentoo boot and wired SSH. See the
[build, licensing and image guide](docs/rg-sp-rocknix-kernel.md).

## Stock kernel packages

`sys-kernel/rg-sp-anbernic-kernel-bin` (4.9.170) and
`sys-kernel/rg-ds-plus-anbernic-kernel-bin` (6.1.141) package checksum-pinned,
locally supplied vendor kernels, DTBs and selected matching Wi-Fi modules.
They do not download vendor binaries or modify the boot setup. See the
[local-input and licensing guide](docs/anbernic-stock-kernels.md) for extraction,
installation and the unresolved stock-source/redistribution boundary.

## melonDS DS emulator core

`games-emulation/libretro-melondsds` builds upstream melonDS DS 1.4.0 for
libretro frontends such as mono-retro-player. It defaults to JIT and threaded
software rendering, with checksum-pinned source archives and offline builds.
See the [installation, source and licensing guide](docs/libretro-melondsds.md).

`games-emulation/libretro-monomelon` is the tuned variant, with internal-call
optimization and optional PGO trained on existing open-source Nitro Engine
demos. It installs alongside upstream. See [monoMelon](docs/monomelon.md).

## Sources and licensing

See [the source and licensing inventory](docs/rg-ds-plus-rocknix-kernel.md) for
the exact upstream revision, patch order, notices and excluded components.
Our original ebuilds and support files use MIT; imported files retain
their own notices. The top-level [LICENSE](LICENSE) does not replace those
notices or grant rights to unrelated vendor firmware.

Keep source archives alongside ROCKNIX kernel binary releases. For that package,
the original Linux archive plus this overlay revision contains the source, patches,
configuration and build instructions needed to reproduce the packaged kernel.
Use Portage's checksummed distfile cache for offline builds. A preserved copy
of the original kernel archive is also attached to the Gitea source release.

Gitea is the current home. Public GitHub publication is a separate future step;
no credentials or private machine configuration belong in this repository.

## Checks

`make check` verifies shell syntax and the integrity of all imported inputs.
Run Gentoo package QA with `pkgcheck scan sys-kernel/rg-ds-plus-rocknix-kernel`.
After installing into a disposable test root, check artifacts with:

```sh
make check-package ROOT=/path/to/test-root RELEASE=7.0.2-mono-rgdsplus-rocknix-r0
```

The artifact check needs `sys-apps/dtc` and `sys-apps/kmod`. It reads files and
resolves module dependencies without loading any modules.

# RG SP compiled kernel and boot chain

The first hardware acceptance target is Gentoo boot and SSH through an ASIX
AX88179 USB Ethernet adapter. A successful package build alone does not
establish that the RG SP boots it. Display, gamepad, audio, Wi-Fi, Bluetooth,
suspend and charger-connected shutdown are separate acceptance work.

## Source baseline

The baseline is ROCKNIX release `20261001`, commit
`c445081a59518f37d9776e5412dd7b14910696f7`:

| Package | Upstream input | Selected recipe |
| --- | --- | --- |
| `sys-kernel/rg-sp-rocknix-kernel-7.2` | Linux 7.2, kernel.org archive | `projects/ROCKNIX/packages/linux/package.mk`, H700 case |
| `sys-boot/rg-sp-trusted-firmware-a-2.15.0` | TrustedFirmware-A v2.15.0 archive | `packages/tools/atf/package.mk`, `PLAT=sun50i_h616` |
| `sys-boot/rg-sp-rocknix-u-boot-2026.01` | U-Boot v2026.01 archive | H700 `u-boot-DDR3` and `u-boot-DDR4` recipes |

The source archives have checksum-pinned Manifests. `rg-sp-upstream-files.tsv`
records original paths and SHA256 values for all copied inputs. ROCKNIX inputs
were also compared with the Git blob identities in the pinned upstream tree.
The two supplementary license texts come from Gentoo commit
`8939c3d8854b01c9a460dc545191bfef14a4ed7c`; their provenance is recorded in
the same inventory.

Kernel preparation applies four `mainline` patches, six `7.2` patches, then
31 enabled H700 patches, in filename order within each group. Disabled patches
are excluded. This retains the selected family baseline, including changes
for other hardware. It does not mix in the separate hsyysy RG35XXSP patch set.
The kernel includes ROCKNIX's RG SP DTS and its patched upstream dependencies;
only the RG SP DTB is requested as a build target.

U-Boot uses the two upstream H700 memory configurations, common DRAM and
AXP717 patches, plus the stored libfdt/SWIG compatibility patch. TF-A is an
exact build dependency; its compiled BL31 is embedded in each SPL/U-Boot image.
No downstream Git checkout, vendor SDK, stock kernel, bootloader binary or
proprietary DRAM training blob is fetched by these recipes.

## Package behavior

Linux's source archive is named 7.2, but its kernel version is **7.2.0**.
The initial package produces release `7.2.0-mono-rgsp-rocknix-r0`; package
revisions change the suffix. Its artifacts are installed under
`/usr/lib/rg-sp-rocknix-kernel/<kernel-release>/`:

- `Image` and `sun50i-h700-anbernic-rg-sp.dtb`.
- The resolved `config`, `System.map` and `Module.symvers`.

The complete configured in-tree modules and depmod indexes go under
`/lib/modules/<kernel-release>/`. Dangling build/source symlinks are removed.
Normal Gentoo module preservation on unmerge applies. There is no prepared
external-module build tree or separate ROCKNIX joypad module in this package.

The configuration starts with the preserved ROCKNIX H700 configuration.
Local changes remove its embedded initramfs, firmware list and hostname;
enable built-in SD-root and AX88179 networking support; and keep firmware-
dependent wireless and generic panel drivers modular. The external panel
data needed by the generic driver is not bundled. Neither Wi-Fi nor a working
screen is a prerequisite for the wired-SSH test.

TF-A installs `bl31.bin` and `bl31.elf` under
`/usr/lib/rg-sp-trusted-firmware-a/2.15.0/`. U-Boot installs separate
`lpddr3/` and `lpddr4/` directories under
`/usr/lib/rg-sp-rocknix-u-boot/2026.01/`, each containing the combined
`u-boot-sunxi-with-spl.bin` and resolved configuration.

These packages never write `/boot`, a boot sector or a physical device.
They honor Portage's compiler and build tools; Nix, Docker and QEMU are not
requirements of a normal ARM64 Gentoo build. The full toolchain/environment
is not locked, and byte-for-byte binary reproducibility is not promised.

## Build and image assembly

Configure this overlay as described in the root README, accept `~arm64` for
the three packages, and build on Gentoo ARM64:

```sh
PKGDIR=/path/to/rg-sp-packages emerge --ask --buildpkg \
  =sys-boot/rg-sp-trusted-firmware-a-2.15.0 \
  =sys-boot/rg-sp-rocknix-u-boot-2026.01 \
  =sys-kernel/rg-sp-rocknix-kernel-7.2
```

Retain the generated `Packages` index with its package directories. Host-tool
dependencies include the normal C toolchain, Python, pyelftools, setuptools,
SWIG, OpenSSL, bison and flex. Portage resolves the per-package declarations.
Source archives can be cached in `DISTDIR` for offline builds.

monobake's separate `rg-sp-rocknix` target consumes these compiled packages
and a clean, committed overlay checkout. It snapshots the source with
`git archive`, excluding Git metadata and ignored build artifacts. The image
uses MBR, a 256 MiB FAT32 boot partition starting at 8 MiB, and an expandable
ext4 root partition second, within the existing 30 GB decimal size.

The selected SPL/U-Boot is placed at byte 8192, with a size check against the
reserved gap. Extlinux loads the explicit RG SP DTB and selects root by its
actual MBR `PARTUUID`. The new monorig profile uses udev and wired DHCP, omits
vendor driver/audio/launcher setup, and does not load Wi-Fi credentials.
Existing stock-kernel targets retain their layouts and configuration.

### Confirm the memory variant

Use the working Gentoo installation for a read-only check:

```sh
ssh monofuel@KNOWN_RG_SP_ADDRESS 'bash -s' < tools/read-rg-sp-dram.sh
```

This follows ROCKNIX's named DRAM-regulator mapping: 1.2 V selects LPDDR3;
1.1 V selects LPDDR4. It rejects missing, conflicting or unknown readings.
If the vendor kernel uses different names, verify the actual rail mapping
before selecting a variant. Vendor DTBs contain multiple profiles and generic
labels; they do not independently establish the unit's memory type. Do not
try different voltages to discover the type.

Then, from monobake, use the verified variant:

```sh
sudo -E /path/to/monobake build rg-sp-rocknix \
  --dram=VERIFIED_VARIANT --overlay=/path/to/mono-overlay \
  --binpkg-dir=/path/to/rg-sp-packages
```

`--dry-run`, `--stage3-timestamp`, `--resume` and `apply` are supported.
Each variant has a separate image filename. Building only creates an image;
flashing requires identifying the designated test card. Keep the working
Gentoo and stock cards intact. First boot is headless; use the USB host port,
DHCP and the existing administrator SSH key.

## Licensing and distribution

Linux and the U-Boot implementation use GPLv2-compatible inputs; complete
source, configuration, patches and build instructions must accompany their
binary distribution. Preserve original notices. The copied software grant's
pinned reference is in `upstream-software-license.txt`; ROCKNIX's broader
noncommercial wording is not treated as an extra restriction on GPL software.

TF-A's actual build inputs include BSD-3-Clause, BSD-2-Clause/FreeBSD and ISC
code, plus LLVM builtins under **Apache-2.0 WITH LLVM-exception**. Those specific
file notices take precedence over its general documentation's older NCSA/MIT
description. The package includes the complete applicable license texts and
an archive of the actual C/assembly/header inputs preserving their notices.
U-Boot embeds BL31 and therefore declares these component licenses and carries
the TF-A documentation too. The LLVM exception text is preserved in full.

No panel data, Wi-Fi/BT firmware, boot logos, stock binaries or proprietary GPU
userspace is imported. Those components need their own provenance and licenses
before a full handheld distribution can include them.

Keep all three original source archives with the exact overlay revision when
publishing the compiled packages. Gitea remains the publication destination;
public GitHub publication is separate.

## Acceptance checks

Run `make check`, package QA, clean ARM64 builds, offline preparation and an
offline rebuild. Check a disposable root containing all three packages with:

```sh
make check-rg-sp-package ROOT=/path/to/disposable/root
```

Verify install/reinstall/unmerge, damaged-artifact rejection and preservation
of unrelated boot/kernel files. Check the compiled boot configurations select
the intended memory variant and support extlinux. Exercise the monobake image
layout and cleanup, root growth, and monorig's vendor/mainline separation.

Hardware acceptance requires SSH to report `rg-sp` and the expected kernel
release, a functioning AX88179 interface, expanded root, reconnection after
reboot, and physically confirmed battery-only shutdown. Record that result
separately; package checks do not substitute for it.

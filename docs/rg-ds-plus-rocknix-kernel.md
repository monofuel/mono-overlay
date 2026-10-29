# RG DS Plus ROCKNIX kernel sources and licensing

## Hardware status

The package builds and installs, but its first FIT test with the stock bootloader
did not reach a working system: the boot logo remained, with no SSH connection
or Ethernet link lights. The verified stock FIT has been restored. Boot
integration remains unresolved; this is not yet a known-working handheld kernel.

## Source selection

- Kernel: upstream `linux-7.0.2.tar.xz`, from
  <https://www.kernel.org/pub/linux/kernel/v7.x/linux-7.0.2.tar.xz>.
- SHA-256: `53591a03294527a48ccb0b9e559e922df8a38554745a1206827ca751d2ca7662`.
- ROCKNIX: release `20261001`, commit
  `c445081a59518f37d9776e5412dd7b14910696f7` in
  <https://github.com/ROCKNIX/distribution>.
- Build selection: `PROJECT=ROCKNIX DEVICE=RK3566 ARCH=aarch64`.

The controlling recipe is **`projects/ROCKNIX/packages/linux/package.mk`**,
which overrides `packages/linux/package.mk`. The project recipe selects the
upstream kernel archive, not the fork referenced by the generic recipe.

`upstream-files.tsv` records every imported file's local path, original path
and SHA-256. Imported payloads are byte-identical to that ROCKNIX commit.

## Patch and build order

The ebuild follows the selected directories in `scripts/unpack`, sorting
filenames within each group:

1. `projects/ROCKNIX/packages/linux/patches/mainline/`.
2. `projects/ROCKNIX/packages/linux/patches/mainline-rockchip/`.
3. `projects/ROCKNIX/packages/linux/patches/7.0/`.
4. `projects/ROCKNIX/devices/RK3566/patches/linux/`.

Other selected patch locations are empty at this revision. In particular,
`packages/linux/patches/rockchip/` belongs to the overridden generic recipe
and is not part of this build. The family patch set is intentionally retained,
including changes for other boards; this package does not try to minimize it.

The project recipe's `post_patch` also copies its generic DSI driver into
the kernel and installs the family device-tree sources. The ebuild reproduces
those steps and adds a build rule for the Plus DTB. It builds only that DTB,
the kernel and configured in-tree modules.

The baseline is `projects/ROCKNIX/devices/RK3566/linux/linux.aarch64.conf`.
Gentoo-specific changes remove the embedded ROCKNIX initramfs and hostname
placeholder, leave firmware external, and set a deterministic package-specific
kernel release. `olddefconfig` resolves configuration for the selected compiler.
No host-specific kernel flags or arbitrary warning suppressions are added.
Revision `-r1` also installs a prepared module build tree under
`/usr/src/linux-7.0.2-mono-rgdsplus-rocknix-r1/` and an absolute `build` link
under its module directory, supporting merged-/usr systems. It retains the
generated headers, module symbol versions and host build tools. The separate
`sys-kernel/rocknix-joypad-0_p20261001` package builds against that exact tree.
Unused dangling links into omitted architecture trees and documentation are
removed. `pkgcheck` flags the absolute module-build link; it is intentional
because the same binary package must work with merged-/usr and traditional
`/lib` layouts. The original revision remains available as the initial artifact
baseline, so `RedundantVersion` is also expected while both revisions remain.
The Plus DTB retains upstream `unit_address_vs_reg` warnings for the two GPU
`power_model` nodes. These are not corrected as part of preserving this source
baseline; compiling the DTB is not a device-tree schema or hardware validation.

Revision `-r2` enables `CONFIG_FB_SIMPLE=y` for an early console using the
stock bootloader's existing logo scanout. It retains the DRM configuration
and does not enable simpledrm, keeping native DRM device numbering unchanged.
It needs a boot-time simple-framebuffer descriptor and a firmware-filled
reserved-memory reference; monobake's `prepare-debug` supplies that descriptor.
The matching controller package is `rocknix-joypad-0_p20261001-r1`, built for
`7.0.2-mono-rgdsplus-rocknix-r2`. Kernel/module package checks and a QEMU
simplefb smoke test pass; this does not establish a working physical boot.

## License inventory

| Input | License basis | Handling |
| --- | --- | --- |
| Upstream Linux archive | Kernel `COPYING`, `LICENSES/` and individual file notices; combined kernel GPL-2.0-only | Preserve the original source archive and all existing notices. |
| Existing-file kernel patches | Licenses of modified kernel files; ROCKNIX's README identifies software as GPLv2 and bundled modifications under the modified software's license | Preserve complete patches, authorship and embedded notices; use as kernel modifications. |
| Restored input-polldev source/header | Explicit GPL-2.0-only SPDX notices | Preserve notices. |
| Added AW87391 amplifier driver | Explicit GPL-2.0-only SPDX notice | Preserve notice. |
| Added RGB20 Pro device tree | Explicit GPL-2.0-or-later OR MIT notice | Preserve both alternatives; use under GPLv2 for this package. |
| Added X35s device tree | Original ROCKNIX software covered by its README's GPLv2 statement; includes the kernel's X55 device tree | Preserve patch author and enclosing GPLv2 notice; no invented SPDX declaration. |
| Copied Plus/DS/RK2023 device trees | Explicit GPL-2.0-or-later OR MIT notices | Preserve both alternatives; use under GPLv2. |
| Copied generic DSI panel driver | Explicit GPL-2.0 SPDX and GPL v2 module notice; ROCKNIX/Purism copyright notices | Preserve all notices. |
| Generated kernel configuration | ROCKNIX software licensing statement; configuration data for its kernel build | Preserve the original file and document local configuration changes. |
| New ebuild, metadata, tests and documentation | MIT | Top-level LICENSE and source headers where appropriate. |

This review covers the selected imported inputs, their new-file notices and
the licensing of the modified upstream kernel files. It does not assert that
every component distributed by ROCKNIX or Anbernic has been audited. ROCKNIX's
README has separate noncommercial/share-alike wording as well as software and
bundled-work sections; this package imports kernel software, not branding or
other assets under that wording. Keep the software licensing statement and
its exact upstream reference in `upstream-software-license.txt`.

The ebuild uses Gentoo `LICENSE="GPL-2"` for the combined kernel. Individual
compatible licenses remain in the source. No missing permission is replaced
with a blanket repository license or an ebuild redistribution restriction.
If an imported component's terms are disputed or found unclear, withhold its
distribution until resolved; do not silently relicense or drop required code.

## Components outside this package

There are no stock kernel/module binaries, firmware blobs, U-Boot/TF-A/DDR
binaries, proprietary GPU userspace, boot logos or Android ramdisks here.
The generic DSI driver is source code; no stock panel dump is included.

ROCKNIX's board support can require separate Wi-Fi/Bluetooth firmware and an
AW88166 amplifier profile. Regulatory data is also external in this package.
Those inputs need their own licenses and integration before a complete device
image can be distributed. Kernel-source licensing does not cover those files.
The Plus device tree references `rocknix-singleadc-joypad`; ROCKNIX supplies
that controller driver through its separate `rocknix-joypad` package. It is
not an in-tree module and is outside this kernel package, as is the
separate Mali module. This package does not claim complete runtime inputs.

## Companion packages and runtime setup

`sys-kernel/rocknix-joypad-0_p20261001` pins upstream commit
`d02ed13aae08113f6f9e0e9d699cb29bb3450fa2`, selected by the same ROCKNIX
release. Its source headers are GPL-2.0-or-later; the archive retains those
notices and the Hardkernel/littleguy77 credits. Only
`rocknix-singleadc-joypad.ko` is installed, under the exact `-r1` module release.
Rebuild the companion whenever that kernel ABI/release changes.

Use Gentoo's `sys-kernel/linux-firmware` with savedconfig selecting
`rtw88/rtw8821c_fw.bin`, redistribution notices retained, and compression,
initramfs and dist-kernel integration disabled. This kernel configuration
does not enable compressed firmware loading.

`sys-firmware/rg-ds-plus-aw88166-profile-20261001` installs a local, pinned
profile as `aw88166_acf.bin`. Its SHA-256 is
`3f8a6a7fdd2dd550de620caf51828b8d62385542d4aec47450b7e68ce9c23794`.
These are the same bytes as the stock `aw883xx_acf.bin` and ROCKNIX's
`extra-firmware` commit `88b363e67d4f730feb2c3124724d26dfaa88ce76`, path
`RK3566/aw88166_acf.bin`. No redistribution grant is established for that
payload: it is not in Git, is fetched locally, and has bindist/mirror/fetch
restrictions. The ebuild's license does not relicense the binary.

monorig's secret-free `tools/rg_ds_plus_kernel.nim` emits kernel-aware Wi-Fi,
ALSA and launcher setup without reading Wi-Fi credentials. The stock kernel
retains its original driver/audio path; `-r1` uses rtw88, the controller module
and the mainline speaker card. mono-retro provides a separate
`rg-ds-plus-rocknix` device profile. Boot preparation/activation/recovery are
separate operations in monobake; package installation never writes the FIT.

For kernel binary distribution, provide the exact corresponding source:
original kernel archive, this overlay revision with all patches and config,
and build instructions. The Gitea source release preserves the archive and
records the matching overlay commit. A link to a moving upstream branch or an
unrelated vendor tree is not the corresponding source of this package.

## Verification

Run `pkgcheck scan sys-kernel/rg-ds-plus-rocknix-kernel` and build with Portage
in an isolated ARM64 Gentoo environment. Check the final configuration and
release, DTB compatible/model, module vermagic and dependency indexes. Exercise
binary installation, reinstallation and removal in a disposable root while
preserving unrelated kernel and boot files. Repeat preparation/build without
network access after fetching dependencies and distfiles.

Gentoo's default `UNINSTALL_IGNORE="/lib/modules/*"` preserves the module tree
on unmerge. Check that normal unmerge removes the kernel artifacts and package
record while retaining the modules. To test full ownership/removal as well,
reinstall in the disposable root and unmerge with `UNINSTALL_IGNORE=""` for
that invocation only. Both cases must preserve unrelated kernel and boot files.
The ebuild does not override the user's cleanup policy.

With `sys-apps/dtc` and `sys-apps/kmod` available, run the artifact checks:

```sh
bash tests/check-package.sh /path/to/disposable/root 7.0.2-mono-rgdsplus-rocknix-r0
```

Successful compilation and packaging do not establish working displays,
controls, audio, network, charging, suspend or a bootable card. Those require
separate physical validation.

# RG DS Plus ROCKNIX kernel sources and licensing

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
The Plus DTB retains upstream `unit_address_vs_reg` warnings for the two GPU
`power_model` nodes. These are not corrected as part of preserving this source
baseline; compiling the DTB is not a device-tree schema or hardware validation.

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
not an in-tree module and is outside this first kernel package, as is the
separate Mali module. This package does not claim complete runtime inputs.

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

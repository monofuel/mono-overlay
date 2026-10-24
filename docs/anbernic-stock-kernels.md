# Local Anbernic stock kernel packages

| Package | Kernel | Included external modules |
| --- | --- | --- |
| `sys-kernel/rg-sp-anbernic-kernel-bin` | 4.9.170 | `rtl_btlpm.ko`, `8821cs.ko` |
| `sys-kernel/rg-ds-plus-anbernic-kernel-bin` | 6.1.141 | `RTL8821CS.ko` |

These are local-input recipes for the stock kernels used by the Gentoo
bootstrap. They compile nothing and preserve the selected binaries unchanged.
Each package stages `Image` and `board.dtb` under `/usr/lib/<package>/<version>/`,
stages its selected matching modules under the same directory's `modules/`.
The complete stock module collection and its builtin-module metadata are not
available in these inputs. These packages therefore do not populate
`/lib/modules/` or run depmod. In particular, the SP's separate Mali module is
excluded.

The manifests identify exact vendor builds; a matching `uname -r` alone does
not establish ABI compatibility. The raw kernel version cannot receive a
package-specific suffix without rebuilding it. Do not mix another vendor
build's modules with these artifacts. Artifact directories are separate from
the running kernel's module tree and are removed normally on unmerge.

Installing these packages does not change `/boot` or a card's partitions,
bootloader or running kernel. The extracted kernel and DTB must be integrated
into the appropriate device's boot format separately: Android boot format for
the SP and FIT/resource packaging for the Plus. Stock ramdisks, boot headers,
logos, bootloader binaries, firmware and userspace are not installed. Wi-Fi
and amplifier firmware/configuration remain separate inputs. Existing
monobake/monorig boot and module-loading behavior is unchanged.

## Prepare the local distfiles

Run the helper from the overlay checkout. It needs Bash, GNU coreutils and
tar; the Plus path also needs `debugfs` from e2fsprogs. It reads regular files,
requires no root privileges, performs no mounts and downloads nothing.
Output files are verified against the package Manifest before being moved
into the destination. Re-running converges to the same files.

For the SP, supply the pinned BaseOS prepared `rgsp/boot-prefix.img` and
`rgsp/stock-harvest.tar`. These are the inputs already used by monobake,
not a raw backup of a suspect stock card:

```sh
bash tools/prepare-anbernic-stock.sh rg-sp \
  /path/to/rgsp/boot-prefix.img /path/to/rgsp/stock-harvest.tar \
  /path/to/local-distfiles
```

For the Plus, supply the preserved stock card image:

```sh
bash tools/prepare-anbernic-stock.sh rg-ds-plus \
  /path/to/rg-ds-plus-stock-os.img /path/to/local-distfiles
```

The Plus helper temporarily makes a sparse copy of the 5 GiB root partition
so `debugfs` can extract the matching Wi-Fi module without mounting it. Allow
5 GiB of temporary space in the destination filesystem. No other stock root
files are extracted. The original card image remains unchanged.

Configure that destination as Portage's `DISTDIR`, or copy the generated files
into the existing distfile cache. Both ebuilds use bare local filenames in
`SRC_URI` and `RESTRICT=fetch`; Portage will explain missing inputs rather than
fetching stock firmware from a third party.

Accept `~arm64` and the declared licenses explicitly for these two packages:

```text
# /etc/portage/package.accept_keywords/anbernic-stock
sys-kernel/rg-sp-anbernic-kernel-bin ~arm64
sys-kernel/rg-ds-plus-anbernic-kernel-bin ~arm64

# /etc/portage/package.license/anbernic-stock
sys-kernel/rg-sp-anbernic-kernel-bin GPL-2 all-rights-reserved
sys-kernel/rg-ds-plus-anbernic-kernel-bin GPL-2 all-rights-reserved
```

Then emerge the package for the intended device. No ARM compiler, vendor SDK
or package-specific build dependency is needed.

## Pinned input provenance

SP inputs come from BaseOS's
[`prepared-20260914` asset](https://github.com/pvaibhav/BaseOS/releases/download/prepared-20260914/baseos-prepared-20260914.tar.zst).
The complete archive SHA256 is
`86a0186b5ac8ab907dc1d5c24220c9fcd94f38dd9dc3fddb7fb5cf59d4c7719f`.
The recipe does not fetch it. Its two selected members are pinned separately:

- Boot prefix: `be9ce159433dc8b30582353326e860af97201446d27a82480d7bce99ee2c63c5`.
- Stock harvest: `c1459783ea37128ba7aac8fad89ccbab4fadd3c8a974367fc4069fb27ff78d44`.

The Plus input is the complete, independently verified supplied-card backup,
15,634,268,160 bytes, SHA256
`3b938ee9563e920ec3d95d37d6cc172430e55c3edb0a2de8ae38601f1b4d63d2`.
This identifies the actual captured build, not a claim that it matches a
similarly named official download. Other firmware builds require separate
inspection and updated extraction parameters and manifests.

The helper's fixed offsets apply only after those source hashes pass. For the
SP they select the Android v2 kernel and DTB, excluding the ramdisk. For the
Plus they select the uncompressed FIT kernel and FDT, excluding the resource
image, and the Wi-Fi module in stock root partition 6. Package Manifests retain
BLAKE2B/SHA512 hashes and byte sizes for every installed vendor input. The DTB
model strings are generic BSP labels, not reliable model identification.

## Licensing and distribution boundary

Our recipes, helper and documentation are MIT licensed. Linux is GPLv2, and
all three selected vendor modules advertise `GPL` in their module metadata.
Those tags do not prove that corresponding source is available or that every
vendor addition complies with its license. Matching complete vendor source
for these exact kernel/module binaries has not been verified.

The compiled vendor DTBs have no verified source license. Following Gentoo's
[unknown-license convention](https://devmanual.gentoo.org/general-concepts/licenses/index.html),
the packages declare `GPL-2 all-rights-reserved`: GPL-2 describes the kernel;
the latter conservatively records the unresolved DTB permission. It does not
relicense Linux, assert that the GPL kernel is proprietary, or grant rights
to unknown vendor material. Accepting it in Portage grants no new rights.

`RESTRICT="bindist fetch mirror strip"` keeps acquisition manual, marks the
payloads as unsuitable for mirroring or binary redistribution, and avoids
altering precompiled objects. These settings are handling instructions, not a
substitute for permission or corresponding source. Do not upload the inputs,
generated binary packages or images containing them to shared releases while
those issues remain unresolved. Public recipe publication is separate from
redistribution of its locally supplied payloads. No vendor binaries or local
input paths belong in this repository.

## Verification

In a disposable ARM64 Gentoo root, install the selected package and run:

```sh
make check-stock-package ROOT=/path/to/test-root DEVICE=rg-sp
make check-stock-package ROOT=/path/to/test-root DEVICE=rg-ds-plus
```

This needs `sys-apps/kmod` for static module inspection and checks exact
installed bytes, ARM64 kernel/module formats and module release. Also exercise
checksum rejection, reinstall and unmerge while preserving unrelated kernel
and boot files. Packaging checks
do not replace boot testing or authorize changing a working card.

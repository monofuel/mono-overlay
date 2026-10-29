#!/bin/bash
# Copyright 2026 mono-overlay contributors
# SPDX-License-Identifier: MIT

set -euo pipefail

root=${1:?Usage: check-package.sh INSTALL_ROOT KERNEL_RELEASE}
release=${2:?Usage: check-package.sh INSTALL_ROOT KERNEL_RELEASE}
artifacts="$root/usr/lib/rg-ds-plus-rocknix-kernel/$release"
modules="$root/lib/modules/$release"

for name in Image config System.map Module.symvers rk3568-anbernic-rg-ds-plus.dtb; do
    test -s "$artifacts/$name"
done

# ARM64 Image magic is at byte 56, independent of the host architecture.
test "$(od -An -tx1 -j56 -N4 "$artifacts/Image" | tr -d ' \n')" = 41524d64
test "$(fdtget -t s "$artifacts/rk3568-anbernic-rg-ds-plus.dtb" / model)" = 'Anbernic RG DS Plus'
test "$(fdtget -t s "$artifacts/rk3568-anbernic-rg-ds-plus.dtb" / compatible)" = 'anbernic,rg-ds-plus rockchip,rk3568'
grep -Fxq 'CONFIG_INITRAMFS_SOURCE=""' "$artifacts/config"
grep -Fxq 'CONFIG_EXTRA_FIRMWARE=""' "$artifacts/config"
grep -Fxq 'CONFIG_DRM_ROCKCHIP=y' "$artifacts/config"
grep -Fxq 'CONFIG_DRM_PANFROST=m' "$artifacts/config"
grep -Fxq 'CONFIG_RTW88_8821CS=m' "$artifacts/config"
grep -Fxq 'CONFIG_USB_NET_AX88179_178A=y' "$artifacts/config"
grep -Fxq 'CONFIG_EXT4_FS=y' "$artifacts/config"
if [[ $release == *-r0 ]]; then
    test ! -e "$modules/build" && test ! -L "$modules/build"
else
    test -L "$modules/build"
    test "$(readlink "$modules/build")" = "/usr/src/linux-$release"
    build="$root/usr/src/linux-$release"
    test -s "$build/Module.symvers"
    test -s "$build/include/linux/input-polldev.h"
    test "$(cat "$build/include/config/kernel.release")" = "$release"
fi
test ! -e "$modules/source" && test ! -L "$modules/source"

for name in modules.dep modules.alias modules.dep.bin modules.alias.bin; do
    test -s "$modules/$name"
done

wifi="$modules/kernel/drivers/net/wireless/realtek/rtw88/rtw88_8821cs.ko"
test -s "$wifi"
test "$(od -An -tx1 -j18 -N2 "$wifi" | tr -d ' \n')" = b700
vermagic=$(modinfo -F vermagic "$wifi")
test "${vermagic%% *}" = "$release"
modprobe --dirname "$root" --set-version "$release" --show-depends rtw88_8821cs > /dev/null
if [[ -f $modules/extra/rocknix-singleadc-joypad.ko ]]; then
    modprobe --dirname "$root" --set-version "$release" --show-depends rocknix-singleadc-joypad > /dev/null
fi

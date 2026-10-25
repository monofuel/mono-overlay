#!/bin/bash
# Copyright 2026 mono-overlay contributors
# SPDX-License-Identifier: MIT

set -euo pipefail

root=${1:?Usage: check-rg-sp-package.sh INSTALL_ROOT}
release=7.2.0-mono-rgsp-rocknix-r0
kernel="$root/usr/lib/rg-sp-rocknix-kernel/$release"
modules="$root/lib/modules/$release"
firmware="$root/usr/lib/rg-sp-trusted-firmware-a/2.15.0"
bootloader="$root/usr/lib/rg-sp-rocknix-u-boot/2026.01"

for name in Image config System.map Module.symvers sun50i-h700-anbernic-rg-sp.dtb; do
    test -s "$kernel/$name"
done
test "$(od -An -tx1 -j56 -N4 "$kernel/Image" | tr -d ' \n')" = 41524d64
test "$(fdtget -t s "$kernel/sun50i-h700-anbernic-rg-sp.dtb" / model)" = 'Anbernic RG-SP'
test "$(fdtget -t s "$kernel/sun50i-h700-anbernic-rg-sp.dtb" / compatible)" = 'anbernic,rg-sp allwinner,sun50i-h700'
for setting in USB_NET_DRIVERS USB_USBNET USB_NET_AX88179_178A USB_EHCI_HCD \
    USB_OHCI_HCD USB_MUSB_HDRC PHY_SUN4I_USB MMC_SUNXI MSDOS_PARTITION EXT4_FS DEVTMPFS DEVTMPFS_MOUNT; do
    grep -Fxq "CONFIG_$setting=y" "$kernel/config"
done
for setting in RTW88_8821CS DRM_PANEL_MIPI; do
    grep -Fxq "CONFIG_$setting=m" "$kernel/config"
done
grep -Fxq 'CONFIG_INITRAMFS_SOURCE=""' "$kernel/config"
grep -Fxq 'CONFIG_EXTRA_FIRMWARE=""' "$kernel/config"
for name in modules.dep modules.dep.bin modules.alias modules.alias.bin; do
    test -s "$modules/$name"
done
wifi="$modules/kernel/drivers/net/wireless/realtek/rtw88/rtw88_8821cs.ko"
test "$(od -An -tx1 -j18 -N2 "$wifi" | tr -d ' \n')" = b700
vermagic=$(modinfo -F vermagic "$wifi")
test "${vermagic%% *}" = "$release"
modprobe --dirname "$root" --set-version "$release" --show-depends rtw88_8821cs > /dev/null
test ! -e "$modules/build" && test ! -L "$modules/build"
test ! -e "$modules/source" && test ! -L "$modules/source"

test -s "$firmware/bl31.bin"
test "$(od -An -tx1 -j18 -N2 "$firmware/bl31.elf" | tr -d ' \n')" = b700
test -s "$root/usr/share/doc/rg-sp-trusted-firmware-a-2.15.0/build-inputs.tar.xz"
test -s "$root/usr/share/doc/rg-sp-rocknix-u-boot-2026.01/rg-sp-trusted-firmware-a-2.15.0/build-inputs.tar.xz"
pattern=$(mktemp)
trap 'rm -f -- "$pattern"' EXIT
od -An -v -tx1 "$firmware/bl31.bin" | tr -d ' \n' > "$pattern"
printf '\n' >> "$pattern"
for dram in lpddr3 lpddr4; do
    path="$bootloader/$dram/u-boot-sunxi-with-spl.bin"
    test -s "$path"
    test "$(stat -c %s "$path")" -le $((8 * 1024 * 1024 - 8192))
    test "$(dd if="$path" bs=1 skip=4 count=8 status=none)" = eGON.BT0
    grep -Fxq "CONFIG_SUNXI_DRAM_H616_${dram^^}=y" "$bootloader/$dram/config"
    grep -Fxq 'CONFIG_BOOTMETH_EXTLINUX=y' "$bootloader/$dram/config"
    od -An -v -tx1 "$path" | tr -d ' \n' | grep -F -f "$pattern" > /dev/null
done

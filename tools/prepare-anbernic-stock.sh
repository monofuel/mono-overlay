#!/bin/bash
# Copyright 2026 mono-overlay contributors
# SPDX-License-Identifier: MIT

set -euo pipefail

repository=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
device=${1:?Usage: prepare-anbernic-stock.sh DEVICE INPUT... OUTPUT_DIRECTORY}
shift

verify_source() {
    test -f "$1"
    printf '%s  %s\n' "$2" "$1" | sha256sum -c -
}

case "$device" in
    rg-sp)
        test "$#" -eq 3
        source=$(realpath -- "$1")
        harvest=$(realpath -- "$2")
        output=$3
        package=rg-sp-anbernic-kernel-bin-4.9.170
        verify_source "$source" be9ce159433dc8b30582353326e860af97201446d27a82480d7bce99ee2c63c5
        verify_source "$harvest" c1459783ea37128ba7aac8fad89ccbab4fadd3c8a974367fc4069fb27ff78d44
        ;;
    rg-ds-plus)
        test "$#" -eq 2
        source=$(realpath -- "$1")
        output=$2
        package=rg-ds-plus-anbernic-kernel-bin-6.1.141
        verify_source "$source" 3b938ee9563e920ec3d95d37d6cc172430e55c3edb0a2de8ae38601f1b4d63d2
        ;;
    *)
        echo "Unknown device: $device" >&2
        exit 1
        ;;
esac

mkdir -p -- "$output"
work=$(mktemp -d "$output/.stock-kernel.XXXXXXXX")
trap 'rm -r -- "$work"' EXIT

# Offsets describe only the checksum-pinned inputs, not other firmware builds.
if [[ $device == rg-sp ]]; then
    dd if="$source" of="$work/$package-Image" bs=1M \
        skip=$((303104 * 512 + 2048)) count=17686536 iflag=skip_bytes,count_bytes status=none
    dd if="$source" of="$work/$package-board.dtb" bs=1M \
        skip=$((303104 * 512 + 20297728)) count=137564 iflag=skip_bytes,count_bytes status=none
    tar -xOf "$harvest" ./usr/lib/modules/4.9.170/kernel/drivers/bluetooth/rtl_btlpm.ko \
        > "$work/$package-rtl_btlpm.ko"
    tar -xOf "$harvest" ./usr/lib/modules/4.9.170/kernel/drivers/net/wireless/rtl8821cs/8821cs.ko \
        > "$work/$package-8821cs.ko"
else
    dd if="$source" of="$work/$package-Image" bs=1M \
        skip=$((32768 * 512 + 0x2e800)) count=$((0x25a2a00)) iflag=skip_bytes,count_bytes status=none
    dd if="$source" of="$work/$package-board.dtb" bs=1M \
        skip=$((32768 * 512 + 2048)) count=$((0x2de4e)) iflag=skip_bytes,count_bytes status=none
    # debugfs needs a filesystem at offset zero. A sparse copy avoids a loop mount.
    dd if="$source" of="$work/rootfs.img" bs=4M skip=251658240 count=5368709120 \
        iflag=skip_bytes,count_bytes conv=sparse status=none
    (cd -- "$work" && debugfs -R "dump /usr/lib/modules/RTL8821CS.ko $package-RTL8821CS.ko" rootfs.img)
    rm -- "$work/rootfs.img"
fi

manifest="$repository/sys-kernel/${package%-[0-9]*}/Manifest"
awk -v directory="$work/" '$1 == "DIST" {
    for (i = 4; i < NF; i += 2) if ($i == "SHA512") print $(i + 1) "  " directory $2
}' "$manifest" | sha512sum -c -
mv -- "$work/$package-"* "$output/"

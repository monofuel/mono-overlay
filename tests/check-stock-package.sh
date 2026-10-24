#!/bin/bash
# Copyright 2026 mono-overlay contributors
# SPDX-License-Identifier: MIT

set -euo pipefail
shopt -s nullglob

root=${1:?Usage: check-stock-package.sh INSTALL_ROOT DEVICE}
device=${2:?Usage: check-stock-package.sh INSTALL_ROOT DEVICE}
repository=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)

case "$device" in
    rg-sp) release=4.9.170; count=2 ;;
    rg-ds-plus) release=6.1.141; count=1 ;;
    *) echo "Unknown device: $device" >&2; exit 1 ;;
esac

package=$device-anbernic-kernel-bin
artifacts="$root/usr/lib/$package/$release"
modules="$artifacts/modules"
installed=("$modules"/*.ko)
test "${#installed[@]}" -eq "$count"

while read -r kind filename size algorithm digest rest; do
    test "$kind" = DIST
    suffix=${filename#"$package-$release-"}
    if [[ $suffix == *.ko ]]; then
        path="$modules/$suffix"
        test "$(od -An -tx1 -j18 -N2 "$path" | tr -d ' \n')" = b700
        vermagic=$(modinfo -F vermagic "$path")
        test "${vermagic%% *}" = "$release"
    else
        path="$artifacts/$suffix"
    fi
    test "$(stat -c %s "$path")" = "$size"
    # The complete Manifest line also carries SHA512; use its BLAKE2B field here.
    test "$algorithm" = BLAKE2B
    printf '%s  %s\n' "$digest" "$path" | b2sum -c -
done < "$repository/sys-kernel/$package/Manifest"

test "$(od -An -tx1 -j56 -N4 "$artifacts/Image" | tr -d ' \n')" = 41524d64
test "$(od -An -tx1 -N4 "$artifacts/board.dtb" | tr -d ' \n')" = d00dfeed

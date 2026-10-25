#!/bin/bash
# Copyright 2026 mono-overlay contributors
# SPDX-License-Identifier: MIT

set -euo pipefail

sysfs=${1:-/sys}
detected=""
for rail in "$sysfs"/class/regulator/regulator.*; do
    test -f "$rail/name" || continue
    name=$(cat "$rail/name")
    case "$name" in
        vdd-dram|vcc-dram)
            voltage=$(cat "$rail/microvolts")
            case "$voltage" in
                1200000) variant=lpddr3 ;;
                1100000) variant=lpddr4 ;;
                *) echo "Unrecognized DRAM voltage: $voltage" >&2; exit 1 ;;
            esac
            if [[ -n $detected && $detected != "$variant" ]]; then
                echo 'Conflicting DRAM regulator readings' >&2
                exit 1
            fi
            detected=$variant
            ;;
    esac
done
if [[ -z $detected ]]; then
    echo 'No named DRAM regulator found; verify the running board rail mapping before selecting --dram.' >&2
    exit 1
fi
printf '%s\n' "$detected"

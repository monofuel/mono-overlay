#!/bin/bash
# Copyright 2026 mono-overlay contributors
# SPDX-License-Identifier: MIT

set -euo pipefail
shopt -s nullglob
root=${1:?Usage: check-monomelon-package.sh INSTALL_ROOT [LIBDIR] [PF]}
libdir=${2:-lib64}
package=${3:-libretro-monomelon-1.4.0-r1}
core="$root/usr/$libdir/libretro/monomelon_libretro.so"
docs="$root/usr/share/doc/$package"
test -s "$core"
test -s "$root/usr/share/libretro/info/monomelon_libretro.info"
for name in melondsds-LICENSE.txt SOURCES.txt; do
    files=("$docs/$name"*)
    test "${#files[@]}" -eq 1
    test -s "${files[0]}"
done
if [[ $package == libretro-monomelon-1.4.0-r1 ]]; then
    patches=("$docs/libretro-monomelon-1.4.0-cpu-renderer.patch"*)
    test "${#patches[@]}" -eq 1
    test -s "${patches[0]}"
fi
archives=("$docs"/licenses/libretro-common-source.tar.*)
test "${#archives[@]}" -eq 1
tar -tf "${archives[0]}" > /dev/null
symbols=$(readelf --dyn-syms --wide "$core")
awk '$8 ~ /^__gcov_/ { bad = 1 } END { exit bad }' <<< "$symbols"
for symbol in retro_api_version retro_init retro_load_game retro_run retro_serialize retro_unserialize; do
    awk -v symbol="$symbol" '$8 == symbol && $7 != "UND" { found = 1 } END { exit !found }' <<< "$symbols"
done
readelf --dynamic "$core" | awk '/RPATH|RUNPATH/ { bad = 1 } END { exit bad }'
if [[ $root == / ]]; then
    dependencies=$(ldd -r "$core" 2>&1)
    if [[ $dependencies == *"not found"* || $dependencies == *"undefined symbol:"* ]]; then
        printf '%s\n' "$dependencies" >&2
        exit 1
    fi
fi

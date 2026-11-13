#!/bin/bash
# Copyright 2026 mono-overlay contributors
# SPDX-License-Identifier: MIT

set -euo pipefail
shopt -s nullglob
root=${1:?Usage: check-monomelon-package.sh INSTALL_ROOT [LIBDIR] [PF]}
libdir=${2:-lib64}
package=${3:-libretro-monomelon-1.4.0-r12}
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
if [[ $package == libretro-monomelon-1.4.0-r2 || $package == libretro-monomelon-1.4.0-r3 || $package == libretro-monomelon-1.4.0-r4 || $package == libretro-monomelon-1.4.0-r5 || $package == libretro-monomelon-1.4.0-r6 || $package == libretro-monomelon-1.4.0-r7 || $package == libretro-monomelon-1.4.0-r8 || $package == libretro-monomelon-1.4.0-r9 || $package == libretro-monomelon-1.4.0-r10 || $package == libretro-monomelon-1.4.0-r11 || $package == libretro-monomelon-1.4.0-r12 ]]; then
    wrapper=a4c263700dde5b2d4cd4af714a1b3e8a05708cba
    engine=9cee6d4936cf70c677be9ee253650d6f1ecf417a
    if [[ $package == libretro-monomelon-1.4.0-r3 ]]; then
        wrapper=b980e76fc90f890f17a76ff75e6da42eff78caca
        engine=af1e4a005e3478be1d9327f6aedb46fd0b2e9e2a
    elif [[ $package == libretro-monomelon-1.4.0-r4 ]]; then
        wrapper=a2c790780931e40502ed1b54eb53ae7f8a7253dc
        engine=4d22164dc9843fd1ef8f3e87b4782463b39b9f39
    elif [[ $package == libretro-monomelon-1.4.0-r5 ]]; then
        wrapper=e32810b0efb2d67f98febd1d9d2e544f5736f2ba
        engine=b15171a362341432ae74b0dba5985fb98d56d31a
    elif [[ $package == libretro-monomelon-1.4.0-r6 ]]; then
        wrapper=26975f1ee151bae485ec7c64bc58d88872a7580b
        engine=a99475c08eb8f298dc9c0c10e31aba123633bafe
    elif [[ $package == libretro-monomelon-1.4.0-r7 ]]; then
        wrapper=85fbdd3f40a2d1586c34c70e8d23a739659cf85e
        engine=397f7d4d067ccc9e4e73a00128871422c5ed8fb0
    elif [[ $package == libretro-monomelon-1.4.0-r8 ]]; then
        wrapper=213e6eeab1e34e7f3d0e3ce871b511213fa1e120
        engine=1b9c2121492f26709f29d709c1d43de8012e6d56
    elif [[ $package == libretro-monomelon-1.4.0-r9 ]]; then
        wrapper=c705c10385d4797ad8a83f56cdc69e5f202837b8
        engine=09556fef981d01d05888b0a55d0a0baddda7a82d
    elif [[ $package == libretro-monomelon-1.4.0-r10 ]]; then
        wrapper=48228a8cc1a089d0b5fdedb504aeda64ddd01fcc
        engine=f2b8b7e5fae49e0cf786433de12cc9b866b37973
    elif [[ $package == libretro-monomelon-1.4.0-r11 ]]; then
        wrapper=e657f86ae4ffe4f7479ba74cc794cce20d50fbf6
        engine=a14c1f0c82137f3a2f0f428cf3c8dc05e4211552
    elif [[ $package == libretro-monomelon-1.4.0-r12 ]]; then
        wrapper=ed9b744447a57edc9127b87fb3f60a7bb1e457cc
        engine=ab394a2fe8b1cf815f0f080fc0a187be29b37c0e
    fi
    sources=("$docs/SOURCES.txt"*)
    case ${sources[0]} in
        *.bz2) source_text=$(bzip2 -dc "${sources[0]}") ;;
        *.gz) source_text=$(gzip -dc "${sources[0]}") ;;
        *) source_text=$(cat "${sources[0]}") ;;
    esac
    grep -Fxq "melonds-ds monofuel/melonds-ds $wrapper" <<< "$source_text"
    grep -Fxq "MELONDS monofuel/melonDS $engine" <<< "$source_text"
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

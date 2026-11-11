#!/bin/bash
# Copyright 2026 mono-overlay contributors
# SPDX-License-Identifier: MIT

set -euo pipefail
output=${1:?Usage: prepare-monomelon-training.sh OUTPUT_DIRECTORY}
mkdir -p "$output"
output=$(realpath "$output")
image=docker.io/skylyrac/blocksds@sha256:6ffe8acad0a8beb35113086d1374ee5fdb072eacb5693bf221d11ee7f13c5afc
revision=06a1f37f3562e8a43f78955b66b1fdcf0e38e21f
archive="$output/nitro-engine-$revision.tar.gz"
curl --fail --location --output "$archive" \
    "https://codeberg.org/SkyLyrac/nitro-engine/archive/$revision.tar.gz"
printf '%s  %s\n' 111c704071fd4ddba243c606c13e53d88d960bb799ef56f8bc0777c6ebb68691 "$archive" | sha256sum -c -
test ! -e "$output/monomelon-training-1"
mkdir "$output/monomelon-training-1"
cp "$archive" "$output/monomelon-training-1/"
cp "$0" "$output/monomelon-training-1/prepare.sh"
docker pull "$image"
docker run --rm -i --network=none --user "$(id -u):$(id -g)" \
    --mount "type=bind,source=$output,target=/work" --workdir /work "$image" bash -s <<'BUILD'
set -euo pipefail
bundle=/work/monomelon-training-1
mkdir /work/sdk-build
tar -xf /work/nitro-engine-*.tar.gz -C /work/sdk-build
source=/work/sdk-build/nitro-engine
mkdir "$bundle/roms" "$bundle/licenses" "$bundle/maps"
cp -a "$source/licenses" "$bundle/licenses/nitro-engine"
cp -a "$BLOCKSDS/licenses" "$bundle/licenses/blocksds"
cp -a "$BLOCKSDS/libs/libnds/licenses" "$bundle/licenses/libnds"
cp "$BLOCKSDS/sys/arm7/main_core/COPYING" "$bundle/licenses/arm7-COPYING"
cp "$BLOCKSDS/libs/libnds/include/nds/arm9/console.h" "$bundle/licenses/console-header.txt"
wf-pacman -Q > "$bundle/SDK-PACKAGES.txt"
for example in effects/fog effects/shading_alpha_outlining loading/paletted_texture other/dual_3d_modes; do
    name=${example##*/}
    make -C "$source/examples/$example" -j2 "build/$name.elf"
    # Use the existing minimal ARM7 and omit the optional SDK logo/banner.
    "$BLOCKSDS/tools/ndstool/ndstool" -c "$bundle/roms/$name.nds" \
        -7 "$BLOCKSDS/sys/arm7/main_core/arm7_minimal.elf" \
        -9 "$source/examples/$example/build/$name.elf"
    cp "$source/examples/$example/build/$name.map" "$bundle/maps/"
done
BUILD
for notice in COPYING.picolibc COPYING3 COPYING.RUNTIME; do
    if [[ $notice == COPYING.picolibc ]]; then
        url="https://codeberg.org/WonderfulToolchain/wf-picolibc/raw/commit/40c274b4a/$notice"
        checksum=80a8d14adb2548513e9e86803bbc4b3c97423533efcea8e04fe9814996fb2974
    else
        url="https://codeberg.org/WonderfulToolchain/gcc/raw/commit/be93d9d35bf/$notice"
        if [[ $notice == COPYING3 ]]; then
            checksum=8ceb4b9ee5adedde47b31e975c1d90c73ad27b6b165a1dcd80c7c545eb65b903
        else
            checksum=9d6b43ce4d8de0c878bf16b54d8e7a10d9bd42b75178153e3af6a815bdc90f74
        fi
    fi
    curl --fail --location --output "$output/monomelon-training-1/licenses/$notice" "$url"
    printf '%s  %s\n' "$checksum" "$output/monomelon-training-1/licenses/$notice" | sha256sum -c -
done
printf '%s\n' "Nitro Engine: $revision" "SDK image: $image" \
    'Example sources: CC0-1.0; Nitro Engine: MIT; linked SDK/runtime code retains its own licenses.' \
    'Picolibc: BSD notices in COPYING.picolibc; libgcc: GPLv3 with GCC Runtime Library Exception.' \
    'The SDK minimal ARM7 is used; no SDK logo/banner or Wi-Fi payload is added.' \
    > "$output/monomelon-training-1/BUILD.txt"
(cd "$output/monomelon-training-1"; sha256sum roms/*.nds > ROMS.sha256)
tar --sort=name --mtime=@0 --owner=0 --group=0 --numeric-owner \
    -C "$output" -cJf "$output/monomelon-training-1.tar.xz" monomelon-training-1
sha256sum "$output/monomelon-training-1.tar.xz"

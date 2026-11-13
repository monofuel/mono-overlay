# monoMelon

`games-emulation/libretro-monomelon` builds melonDS DS 1.4.0 with
`-fno-semantic-interposition` and optional profile-guided optimization (PGO).
Revision `1.4.0-r1` also batches ARM64 background-tile rendering with NEON and
skips sprite-priority passes that cannot draw anything. Other architectures
retain scalar tile rendering; partial tiles and mosaic keep their scalar paths.
It installs `monomelon_libretro.so` alongside the unmodified upstream package.
The runtime libretro identity remains `melonDS DS` for frontend compatibility.

Revision `1.4.0-r2` builds the same changes directly from the `master` branches
of [our wrapper fork](https://github.com/monofuel/melonds-ds/tree/master) and
[engine fork](https://github.com/monofuel/melonDS/tree/master). It applies no
source patches in the ebuild. Both archives are pinned to full commit hashes;
the wrapper's default engine pin matches the ebuild. Other dependency revisions,
compiler settings and PGO training are unchanged. The older recipes and patches
remain available for rollback.

Revision `1.4.0-r3` also copies groups of four pixels when the scalar color
compositor is guaranteed to return their original values. It handles ordinary
layers without active primary effects and opaque 3D where effects cannot alter
the result. Other pixels retain the scalar path. Paired package comparisons
show a small **1.56% / 1.30%** overworld throughput gain over r2; full speed is
still unresolved.

Revision `1.4.0-r4` moves software 2D pixel work to a separate worker in batches
of 16 scanlines. Register latches and VRAM updates keep their original emulated
timing; immutable snapshots preserve mid-frame changes. Capture and raw VRAM/FIFO
display modes stay inline. State operations drain the worker and retain window
carry. The fork includes differential renderer fixtures; the ebuild still uses
pinned source archives and the same four open training demos.

Revision `1.4.0-r5` adds ordered per-row polygon lists and three software 3D
workers, preserving polygon order and retaining serial rendering for shadows.
The workers use private buffers, and state changes wait for pending work.

Revision `1.4.0-r6` caches scheduler deadlines and unchanged palette/OAM
snapshots, uses eight-line 2D batches and adds shared AArch64 JIT dispatch tails.
It retains block boundaries, invalidation checks and the original IRQ handling.
The forks include standalone scheduler, snapshot, dispatch and renderer tests.
Compiler flags, other dependency pins and the four open PGO workloads are unchanged.
The measured CPU gains do not yet establish the full-speed/headroom goal.

Revisions `1.4.0-r7` and `r8` route geometry FIFO writes before general dispatch
and skip clipping passes for polygons already inside the view volume. Per-word
timing, power guards, vertex colour rounding and outside-polygon clipping are
preserved. Both revisions retain the existing compiler flags and open PGO inputs.

Revision `1.4.0-r9` defers perspective-factor division until a Z-buffered pixel
passes depth testing, retaining the original arithmetic and W-buffer behavior.
R9 is installed on the DS Plus; the full-speed/5% headroom goal is still open.

Revision `1.4.0-r10` keeps the original depth comparisons inline instead of
calling through a function pointer for each pixel. It retains r9's arithmetic,
compiler flags, dependencies and four open PGO demos. The fresh package, eight
ARM64 fixtures and native video/PCM comparisons pass. Packaged performance is
mixed, so r9 remains installed while further CPU work is tested.

See [tweaks and measured performance](monomelon-performance.md) for each
optimization's contribution and the Lost in Blue comparison on the RG DS Plus.

## Install

```sh
echo 'games-emulation/libretro-monomelon ~arm64' > /etc/portage/package.accept_keywords/monomelon
echo 'games-emulation/libretro-monomelon jit pgo -opengl' > /etc/portage/package.use/monomelon
emerge --ask --buildpkg games-emulation/libretro-monomelon
```

Select `/usr/lib64/libretro/monomelon_libretro.so` in the frontend. On systems
using another library directory, substitute that directory. The ebuild does not
change launchers, migrate saves, or replace the upstream core.

Without `pgo`, this is one ordinary optimized build. With `pgo`, it builds an
instrumented core, runs four existing Nitro Engine demos for 360 frames each,
then rebuilds in the same directory with the collected profiles. It preserves
JIT and threaded software rendering; no frameskip or accuracy reduction is added.
LTO remains disabled, matching the upstream package.
Release builds explicitly disable C/C++ assertions with `NDEBUG`.

Training uses a small Nim program and its standard library. It exercises fixed
demo controls, consumes video and audio without opening devices, checks for
nonuniform video output, and fails the build on a rejected ROM or training error.
It uses fresh temporary system data and the core's built-in BIOS/firmware
replacements. It never reads a user's games, saves or system directory.

PGO currently requires GCC. `dev-lang/nim` is a build-host dependency only when
`pgo` is enabled. Gentoo
currently does not keyword that dependency for ARM64; native ARM64 builders need
to accept its missing keyword explicitly (`dev-lang/nim **` in
`package.accept_keywords`). Binary-package installation does
not require Nim on the handheld. PGO takes two core compilations, and distcc
keeps profile-generating/profile-using compilations local.

## Training inputs and licensing

The checksummed `monomelon-training-1.tar.xz` release contains four unmodified
Nitro Engine 0.16.0 examples: `fog`, `shading_alpha_outlining`,
`paletted_texture` and `dual_3d_modes`. It includes the original source archive,
preparation script, linker maps, ROM hashes, SDK package versions and notices.

Recreate it with:

```sh
bash tools/prepare-monomelon-training.sh /path/to/empty/output
```

The script verifies the pinned Nitro Engine archive and uses the official
BlocksDS 1.24.0 developer image pinned by digest. Docker is needed only for
preparing this bundle, not for emerging monoMelon. The SDK's existing minimal
ARM7 is used; the optional logo/banner and default Wi-Fi ARM7 are omitted.
The four demos retain their existing code and assets. No benchmark ROM was
written for this package.

Nitro Engine is MIT; its examples are CC0. Linked SDK/libnds/ARM7 and Picolibc
code retain their own permissive notices. GCC runtime notices and its Runtime
Library Exception are included. The combined ROMs are **not entirely CC0**.
There are no commercial ROMs, private save states or Nintendo BIOS/firmware
dumps in the training archive. Training notices are also installed under the
package's documentation directory.

Dependencies and source-preservation requirements follow
[the upstream package](libretro-melondsds.md). For `r2` and later, preserve both fork
archives, which contain the former build fixes and renderer patch, together
with all other Manifest distfiles and this overlay revision. Installed
`SOURCES.txt` identifies the wrapper and engine commits. The renderer and its
reference test remain GPL-3.0-or-later with their existing copyright notices.
For the older `r1`, preserve its installed renderer patch and upstream archives.
The overlay's MIT license does not relicense the emulator's GPL code.
Keep all Manifest distfiles and this overlay revision alongside binary releases.

## Cross builds

PGO executes target binaries. A native build needs no runner setting. A cross
build must set `MONOMELON_PGO_RUNNER` to an executable that runs the target
training command, for example `/usr/bin/qemu-aarch64`. Configure the target
sysroot normally; for QEMU, set `QEMU_LD_PREFIX` and use `QEMU_SET_ENV` to give
the target loader its ARM64 libstdc++/libgcc search path when those libraries
live outside the sysroot. Do not set a host-wide `LD_LIBRARY_PATH` to ARM64
libraries. The same runner interface can execute training on a target machine.

Profiles stay in the current Portage build directory. They are generated from
the current sources/toolchain, not downloaded as game-specific profiles.
Coverage mismatches fail the build; unexercised files may report missing-profile
warnings and retain ordinary optimization through `-fprofile-partial-training`.

## Validation and saves

```sh
bash tests/check-monomelon-package.sh / lib64 libretro-monomelon-1.4.0-r4
```

The [engine fork's tile test](https://github.com/monofuel/melonDS/tree/master/tests/monomelon)
has a deterministic scalar-reference test covering 6.4 million
pixels, including both palette depths, flips, all background layers, window
masks and transparent indices. On ARM64, from the pinned engine source root:

```sh
c++ -O2 -std=c++17 -Isrc \
  tests/monomelon/test-text-neon.cpp -o /tmp/test-monomelon-text-neon
/tmp/test-monomelon-text-neon

c++ -O2 -std=c++17 -Isrc \
  tests/monomelon/test-unblended.cpp -o /tmp/test-monomelon-unblended
/tmp/test-monomelon-unblended
```

The same test can be cross-compiled and run with a matching ARM64 QEMU sysroot.
It checks the tile helper; whole-engine scroll, VRAM and sprite integration also
need game-output comparisons. The color test checks four million randomized
pixels and exhaustive flag/mode/primary-target combinations against scalar
color effects. The performance guide records whole-core comparisons.

Changing the core changes mono-retro's save-state identity hash. Use a separate
save directory and preserve the original core and states. For these same-engine
1.4 builds, verified original states can be imported and re-exported through the
new core's serialization API; do not rewrite PNG identity metadata to bypass
the normal checks. In-game SRAM remains the preferred portable save format.

Open-demo training is reproducible but its performance benefit is workload
dependent. Compare real games against the non-PGO build before treating PGO as
a universal improvement.

# monoMelon

`games-emulation/libretro-monomelon` builds upstream melonDS DS 1.4.0 with
`-fno-semantic-interposition` and optional profile-guided optimization (PGO).
It installs `monomelon_libretro.so` alongside the unmodified upstream package.
The runtime libretro identity remains `melonDS DS` for frontend compatibility.

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

The emulator, dependencies, two packaging patches, exact source revisions and
source-preservation requirements match [the upstream package](libretro-melondsds.md).
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
bash tests/check-monomelon-package.sh / lib64
```

Changing the core changes mono-retro's save-state identity hash. Use a separate
save directory and preserve the original core and states. For these same-engine
1.4 builds, verified original states can be imported and re-exported through the
new core's serialization API; do not rewrite PNG identity metadata to bypass
the normal checks. In-game SRAM remains the preferred portable save format.

Open-demo training is reproducible but its performance benefit is workload
dependent. Compare real games against the non-PGO build before treating PGO as
a universal improvement.

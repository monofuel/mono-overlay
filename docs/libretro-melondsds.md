# melonDS DS libretro core

`games-emulation/libretro-melondsds` builds upstream
[melonDS DS 1.4.0](https://github.com/JesseTG/melonds-ds/releases/tag/v1.4.0).
It supplies an emulator core for a libretro frontend.

## Install

```sh
echo 'games-emulation/libretro-melondsds ~arm64' > /etc/portage/package.accept_keywords/melondsds
echo 'games-emulation/libretro-melondsds jit -opengl' > /etc/portage/package.use/melondsds
emerge --ask --buildpkg =games-emulation/libretro-melondsds-1.4.0::mono-overlay
```

The core is installed under `/usr/$(get_libdir)/libretro/`, normally
`/usr/lib64/libretro/melondsds_libretro.so` on Gentoo ARM64. Core metadata goes
under `/usr/share/libretro/info/`. The frontend must select this packaged path;
the package does not replace unmanaged copies under `/usr/local`.

JIT and threaded software rendering are enabled by default. `opengl` is optional
and disabled by default; its classic renderer requires desktop OpenGL 3.2, and
its compute renderer requires 4.3. OpenGL ES is not supported by this release.
Software rendering needs neither X11 nor Wayland. The package honors Portage's
compiler flags and uses the Release build type. Upstream's automatic LTO is
disabled, preserving a separate choice for future optimization experiments.

For the RG DS Plus, existing MLE distcc configuration can offload compilation.
Opt this package into `mle-builder-distcc` through `package.env`, followed by a
package environment limiting `MAKEOPTS` and `NINJAOPTS` to `-j2`. Set the desired
Cortex-A55 optimization flags there. Linking still happens on the handheld.

After installation, run the artifact check on the target:

```sh
make check-melondsds-package ROOT=/ LIBDIR=lib64
```

## Sources and licenses

The ebuild pins upstream release commit
`f394adbacb5722ee97c1b37c8064da9a25818310` and all eleven FetchContent dependencies
to complete commits. The emulator engine is upstream's selected
`JesseTG/melonDS` revision `16f127dbb587a73371827ce79689c5d237c4b59b`, not a
Monofuel fork. Portage downloads the archives in `SRC_URI`, verifies their
Manifest hashes, and provides their unpacked directories to CMake. Configure and
compile use disconnected FetchContent; they do not clone Git branches or fetch
additional dependencies. Runtime dependency libraries bundled by upstream are
built from these sources. CMake and Ninja are normal build dependencies; optional
OpenGL headers come from `media-libs/libglvnd`.

Two packaging patches make Git optional for source archives and let upstream's
CMake modules find externally populated dependency directories. They do not
change emulator behavior.

The wrapper and engine use GPL-3-or-later. Bundled components retain their own
GPL, BSD, MIT, Zlib, Unlicense and font OFL notices, reflected in the ebuild's
`LICENSE` field. Upstream's generated `melondsds-LICENSE.txt`, available dependency
license files and exact `SOURCES.txt` are installed under
`/usr/share/doc/libretro-melondsds-1.4.0/`. Because libretro-common keeps licenses
in individual source/header files, its complete pinned source archive is also
installed there under `licenses/`. The overlay's MIT license applies to our
original packaging; it does not relicense the core, its dependencies or patches
to upstream code.

Keep all Manifest-listed source archives and this overlay revision alongside
any distributed binary packages, so recipients can obtain their corresponding
source and build instructions. No proprietary Anbernic emulator or Nintendo
firmware dump is included. Upstream's BSD-licensed replacement BIOS is included
with its attribution.

## Upgrading from the manual 1.2.0 core

Preserve the old core and its save directory before changing frontend paths.
The old engine uses save-state format 12.1; this release uses 14.0. Old states
are not a supported migration format, and mono-retro's PNG state envelopes also
bind states to the exact core's hash. Do not edit the hash to bypass that check.

Use a separate save directory for the new core, seeded from copies of the
in-game SRAM and generated system data. The original three comparison slots
remain usable with the preserved 1.2.0 core. Progress existing only in an old
state must first be saved in-game with the old core before carrying its SRAM
forward. New 1.4 states can then be created normally.

# monoMelon tweaks and performance

On the Anbernic RG DS Plus, monoMelon's open-demo PGO build improves Lost in
Blue overworld throughput by **20–21%** over the installed upstream 1.4.0
build. The measured scenes reach **77–82% of normal game speed**; inventory
is near full speed. These measurements were collected on November 10–11, 2026.

## What changed

The emulator uses the same pinned upstream melonDS DS 1.4.0 sources and engine
as [the upstream package](libretro-melondsds.md). The two existing CMake patches
handle source-archive packaging. The performance work changes compiler settings
and training, without changing emulated hardware behavior or rendering settings.

### CPU and release settings

The tested builds use GCC 16.2.1 with `-O3 -mcpu=cortex-a55 -pipe`.
Those flags were already enabled in the installed upstream baseline, so they
receive no separate improvement percentage here.

monoMelon explicitly retains `-DNDEBUG` in CMake's Release flags to disable
C/C++ assertions. The cross-build controls also use `NDEBUG`; its contribution
relative to the installed Gentoo baseline was **not measured independently**.
JIT, block size 32, disabled JIT fast memory, threaded software rendering and
disabled LTO are shared test settings, rather than new gains claimed here.

### Internal-call optimization

`-fno-semantic-interposition` lets GCC optimize calls within the shared core
without preserving runtime replacement of internal functions. This permits
direct calls and inlining. Baseline disassembly showed renderer functions such
as `TextureLookup` and `RenderPixel` being called through PLT stubs.

The initial experiment compared otherwise matching cross builds with and
without this flag. This isolates its effect from differences between the
installed package and the cross-build environment.

### Profile-guided optimization

PGO adds an instrumented build, a training run and a rebuild using the collected
profiles. It helps GCC choose inlining, branch layout and other optimizations
using the code paths exercised during training.

Two training choices were tested:

- **Private game-trained experiment:** the three Lost in Blue states plus
  short walking sequences. This establishes a targeted comparison point.
- **Shipped open-demo training:** four existing Nitro Engine 0.16.0 demos,
  360 frames each: fog, shading/alpha/outlining, paletted textures and dual-screen
  3D. The ebuild runs them through the headless Nim trainer using built-in
  BIOS/firmware replacements. Training requires no commercial game or saves.

These are alternative PGO builds. Open-demo PGO replaces the game-trained
profile; it is not another optimization stacked on top of that profile.

## Improvement at each measured step

These are **relative throughput gains**, calculated as
`100 * (new FPS / reference FPS - 1)`. Gains multiply rather than add.

| Change | Reference build | Overworld 1 gain | Overworld 2 gain |
| --- | --- | ---: | ---: |
| Add `-fno-semantic-interposition` | Matching cross build without the flag, Nov 10 | **12.34%** | **10.38%** |
| Add private game-trained PGO | No-interposition build, Nov 10 | **8.15%** | **8.77%** |
| Add open-demo PGO | No-interposition reference, Nov 11 | **6.36%** | **5.49%** |
| Deployed monoMelon, all settings combined | Installed upstream package, Nov 11 | **20.93%** | **20.05%** |

The two batches have their own reference runs. Do not combine figures across
batches to attribute an exact contribution to a flag. In particular, the
initial control rebuild itself differs from the installed baseline, most
visibly in inventory. Inventory also approaches the player's target cadence,
so it is unsuitable for measuring further throughput gains.

## Final playback comparison

The deployment batch reran the installed core, the no-interposition reference,
the private game-trained core and the shipped open-trained core together.
Values below are **percentages of normal game speed**, not improvement rates.

| Saved scene | Installed upstream | No-interposition reference | Private game-trained PGO | Open-demo monoMelon |
| --- | ---: | ---: | ---: | ---: |
| Slot 1: overworld | 63.89% | 72.65% | 79.88% | **77.27%** |
| Slot 2: overworld | 67.93% | 77.31% | 82.88% | **81.55%** |
| Slot 3: inventory | 92.88% | 98.75% | 98.92% | **98.78%** |

For example, 63.89% to 77.27% is about **13.38 percentage points**, or
**20.93% more throughput** using the unrounded measurements. The open-trained
build takes 3.39% and 1.62% more time per frame than the private game-trained
build in the two overworld scenes.

## Measurement and correctness

- RG DS Plus: RK3568, four Cortex-A55 cores; CPU frequency 1.992 GHz at every
  end-of-run sample. The kernel is the source-built ROCKNIX-derived 7.0.2 build.
- Same mono-retro-player binary and game/state inputs for every comparison.
  Both displays use the paired Panfrost/GLES presentation path.
- Each playback point contains two 240-frame runs, reversing variant order
  for the second pass. FPS is total frames divided by total measured loop time;
  normal game speed is 59.8261 FPS.
- Input is neutral, captures are disabled and OpenAL uses its null backend.
  The core still generates audio; automated playback is silent.
- Separate correctness runs warm 30 frames, then compare hashes of all video
  and PCM output for 120 frames. All three scenes match the upstream baseline
  for every tested variant. Hashing is excluded from playback timings.
- Comparison states are verified against their original core, imported through
  the compatible new core and re-exported through its serialization API.
  Original saves and normal PNG identity checks remain intact.

These are short, scene-specific measurements. Matching output covers the tested
sequences, and performance on other games is unmeasured. The deployed build has
also received manual confirmation that it works on the handheld.

## Build safeguards

The ebuild sets C/C++ flags explicitly on each configure. CMake otherwise
retains the initial cached generation flags across the PGO stages. The first
prototype exposed that mistake during playback and is excluded from the results.

The final build uses `-fprofile-use`, `-fprofile-partial-training` and
`-Werror=coverage-mismatch`. A shortened profile-path prefix avoids oversized
gcov filenames in long Portage paths. The build rejects a final library that
still defines `__gcov_*` instrumentation symbols; the installed-package check
also rejects the instrumented prototype.

See the [build and licensing guide](monomelon.md),
[ebuild](../games-emulation/libretro-monomelon/libretro-monomelon-1.4.0.ebuild),
[Nim trainer](../games-emulation/libretro-monomelon/files/train.nim) and
[open training release](https://github.com/monofuel/mono-overlay/releases/tag/monomelon-training-v1).

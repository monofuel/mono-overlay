# monoMelon tweaks and performance

On the Anbernic RG DS Plus, monoMelon `1.4.0-r1` reaches **81–86% of normal
Lost in Blue overworld speed**, with inventory near full speed. Its CPU-renderer
patch improves throughput **3.6–3.9%** over the preceding open-demo PGO build in
a paired comparison. The earlier compiler/PGO work improves throughput **20–21%**
over upstream in its separate batch. These measurements were collected on
November 10–11, 2026; full-speed overworld gameplay remains unresolved.

## What changed

The emulator uses the same pinned upstream melonDS DS 1.4.0 sources and engine
as [the upstream package](libretro-melondsds.md). The two existing CMake patches
handle source-archive packaging. The original performance work changes compiler
settings and training. Revision `1.4.0-r1` also changes CPU-renderer code,
described below. Neither changes emulated hardware behavior or rendering settings.

### CPU and release settings

The tested builds use GCC 16.2.1 with `-O3 -mcpu=cortex-a55 -pipe`.
Those flags were already enabled in the installed upstream baseline, so they
receive no separate improvement percentage here.

monoMelon explicitly retains `-DNDEBUG` in CMake's Release flags to disable
C/C++ assertions. The cross-build controls also use `NDEBUG`; its contribution
relative to the installed Gentoo baseline was **not measured independently**.
It also changes upstream's default for JIT fast memory: the recorded option
values are disabled in the installed upstream build, and enabled in the cross
controls and deployed monoMelon. Thus the control rebuild's difference includes
this setting; it cannot be attributed solely to removing assertion overhead.
JIT, block size 32, threaded software rendering and disabled LTO are shared
test settings, rather than new gains claimed here.

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

The open-demo trainer currently forces JIT fast memory off, whereas deployed
playback enables it through the release default. Matching training to playback
was tested below and did not improve these workloads, so the shipped trainer
retains its existing setting. The recorded performance gains already include
enabled fast memory during playback.

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

## CPU-only follow-up

The CPU-only follow-up keeps the source-built kernel, CPU frequency, JIT settings
and GPU presentation path fixed. Each compiler candidate regenerates profiles
from the same four open demos. All candidates match baseline video and PCM
hashes in the three game states before performance testing.

The following are headless throughput changes relative to each batch's matching
deployed-core control, using three 360-frame runs per scene. Negative values
mean slower. None justifies replacing the deployed compiler configuration.

| Candidate | Overworld 1 | Overworld 2 |
| --- | ---: | ---: |
| GCC 16 O2 + PGO | -5.43% | -5.69% |
| GCC 16 O3 + PGO + explicit LTO | -0.67% | -1.53% |
| Hidden visibility | -1.99% | -0.20% |
| Remove stack/fortify hardening | -2.84% | -2.15% |
| Clang 22 O3 + PGO | -5.03% | -3.51% |
| Clang 22 O3 + PGO + ThinLTO | -5.02% | -3.88% |

GCC's explicit LTO experiment does build and pass correctness checks, despite
the upstream GCC 15+ compiler-crash workaround that disables its CMake LTO
options. It applies consistent compile/link flags and GCC archive tools.
Clang uses a separately generated LLVM profile and matching ARM64 profile
runtime. Compiler changes, hardening changes and visibility changes remain
experiments; they are not shipped defaults.

### Software-renderer prototypes

Two independent ARM64 NEON prototypes retain exact integer colour arithmetic.
The colour-compositing prototype matches 12.8 million scalar-reference pixels
but is 1.36% / 1.73% slower headless, so it is rejected.

The grouped background-tile prototype matches 6.4 million reference pixels and
all three game video/PCM sequences. Its first headless comparison improves
throughput 1.95% / 1.91%. A five-repeat full-player comparison improves
throughput **1.52% / 1.72%**, reaching **80.17% / 83.77%** game speed versus
**78.97% / 82.35%** in that batch's control. This remains below the chosen 2%
promotion threshold; correctness alone is not a reason to deploy it.

### Where CPU time remains

Fresh profiles of the optimized core separate the main emulation thread from
the 3D worker. Roughly 10–11% of total user CPU samples are generated JIT code;
most samples remain in compiled emulator code. The emulation thread is almost
continuously executing, with little runnable delay. Thread pinning changes
player throughput by less than 1%, so no affinity policy is added.

The 3D worker is also close to the full-speed frame budget. Improving only the
main thread does not guarantee that rendering and presentation can sustain the
target cadence. Existing threaded rendering is important: a diagnostic control
with threading disabled falls from 85.01% to 49.17% in overworld 1.
That comparison changes overlap and synchronization; its difference is not an
exact measurement of renderer execution time.

### CPU-renderer revision (`1.4.0-r1`)

Two exact software-rendering changes are combined:

- Group complete, non-mosaic background tiles into eight-pixel ARM64 NEON
  operations. Palette lookup, transparent indices, window masks, pixel colour
  expansion and upper/lower layer writes retain the scalar behavior. Partial
  tiles and mosaic retain their original paths; other architectures use scalar
  rendering throughout.
- Track which sprite priorities received opaque pixels. Skip an interleave
  pass when that priority cannot contribute. The mask is conservative: replaced
  pixels may leave extra bits set, while mosaic only copies already covered
  priorities. It resets with the sprite line buffer.

The tile helper passes 6.4 million deterministic scalar-reference pixel cases.
All three game scenes match complete video and PCM sequences. The sprite
optimization alone is marginal; the combination improves the five-repeat
prototype player comparison by **2.16% / 2.80%**, reaching **80.40% / 84.64%**
game speed versus **78.70% / 82.34%** in the paired control.

The deployment gate is at least **2% repeatable throughput gain in one
overworld**, at most **1% regression in the other**, and matching output. This
applies to the complete combination. The actual Portage-built revision passes
an independent five-repeat comparison, 360 frames per scene/build, alternating
build order. Both displays use GPU presentation and audio uses the null backend.
Correctness hashing is separate: 30 warmup plus 120 checked frames per scene.

| Scene | Control ms / speed | Packaged r1 ms / speed | Throughput gain |
| --- | ---: | ---: | ---: |
| Overworld 1 | 21.278 / 78.55% | 20.544 / **81.36%** | **3.57%** |
| Overworld 2 | 20.294 / 82.37% | 19.529 / **85.59%** | **3.91%** |
| Inventory | 16.832 / 99.30% | 16.806 / **99.46%** | 0.16% |

The packaged core SHA256 is
`2fd0d706c15712ddec294f276ab9c83b7727d82b0f7123cc8c20180641a30783`.
Remaining overworld throughput requirements are approximately **23% / 17%**
to reach 100%. These are gains needed from the new build, not percentage-point
differences. Each batch has its own control; do not multiply historical batches
to claim an exact end-to-end gain over upstream.

The no-colour-target memcpy addition loses the tile gain, so it is excluded.
A lower-bookkeeping, per-sprite priority mask also offers no measured advantage
over the confirmed combination. GCC/Clang options, training inputs and renderer
quality settings remain unchanged. The engine patch and its test are GPL-3+;
the overlay's MIT packaging license does not relicense them.

## Measurement and correctness

### Headless versus the player

A follow-up comparison uses the deployed open-trained core and the same three
states, with two 360-frame runs per mode and reversed mode order. Headless runs
are uncapped; they still request emulated video and audio. The capture mode adds
the player's normal video/audio buffer capture, without presentation or playback.
Player runs use both GPU displays, null audio, neutral input and disabled captures.
All modes start at the same state without a warmup; output hashing is excluded
from these timing runs.

| Scene | Headless ms / speed | With buffer capture ms / speed | Full player ms / speed |
| --- | ---: | ---: | ---: |
| Overworld 1 | 19.598 / 85.29% | 19.906 / 83.97% | 21.221 / 78.77% |
| Overworld 2 | 18.584 / 89.94% | 18.615 / 89.79% | 20.264 / 82.49% |
| Inventory | 11.903 / 140.42% | 12.097 / 138.18% | 16.858 / 99.15% |

The full player adds about **1.62–1.68 ms** per overworld frame over headless.
This is an end-to-end difference that includes synchronization and contention,
not a measurement of frontend CPU instructions alone. Eliminating the entire
difference would improve throughput by about 8–9%, but the core still exceeds
the 16.715 ms full-speed budget. Both frontend and emulator work remain relevant.
Inventory's uncapped speed demonstrates spare core capacity there; the player
intentionally paces it near 100%.

### Training with fast memory enabled

A separate two-stage Portage build changes only the trainer's fast-memory
option to enabled. It uses the same sources, compiler settings and four demos;
all four training runs pass under QEMU. Its complete video and PCM hashes match
the deployed build in all three game states, using 30 warmup and 120 checked
frames per state. No hashing runs inside the separate performance measurements.

The performance comparison repeats each scene/mode/build three times for 360
frames, changing variant and mode order on the middle pass. Both builds enable
fast memory during playback. The table shows percent of normal game speed.

| Scene | Existing PGO, headless | Fast-memory training, headless | Existing PGO, player | Fast-memory training, player |
| --- | ---: | ---: | ---: | ---: |
| Overworld 1 | 84.88% | 83.20% | 78.61% | 78.13% |
| Overworld 2 | 89.66% | 89.42% | 82.75% | 82.42% |
| Inventory | 140.63% | 139.54% | 99.40% | 99.41% |

There is **no demonstrated performance gain**. Mean overworld throughput is
0.62% / 0.39% lower in the player and 1.98% / 0.27% lower headless. These small
differences do not establish a general regression from fast-memory training;
they do not justify replacing the deployed build either. The original core,
trainer and menu selection remain unchanged. No renderer or NEON changes are
part of this experiment.

### Deployment comparison method

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
[ebuild](../games-emulation/libretro-monomelon/libretro-monomelon-1.4.0-r1.ebuild),
[Nim trainer](../games-emulation/libretro-monomelon/files/train.nim) and
[open training release](https://github.com/monofuel/mono-overlay/releases/tag/monomelon-training-v1).

# monoMelon tweaks and performance

**Benchmark update, November 12:** slot 2 is now the river near the start and
slot 4 is a new ocean scene. Slot 1 remains the cliff and slot 3 the menu.
Monofuel reports cliff/menu feel full speed, with slowdowns around water.
The percentage tables below precede this update unless explicitly marked;
old slot-2 measurements are not river measurements. Fresh profiles are pending.

On the Anbernic RG DS Plus, the installed monoMelon `1.4.0-r4` reaches
**97.35% / 98.66% of normal Lost in Blue overworld speed** in its first three
paired playback runs, with inventory near full speed. The earlier compiler/open-demo-PGO work improves throughput
**20–21%** over its upstream control; `r1` adds **3.6–3.9%**, and `r3` adds
**1.3–1.6%**; r4's batched 2D renderer adds **19.26% / 14.04%** in its package
comparison. These are separate batches,
not percentages to add together. Full-speed overworld gameplay remains unresolved.

## What changed

The ebuild pins our engine and wrapper forks, based on melonDS DS 1.4.0.
Source-archive CMake fixes and renderer changes live in those forks; older
revisions carried them as ebuild patches. The original performance work changes
compiler settings and training, followed by exact CPU-renderer changes in `r1`
and `r3`, then parallel 2D rendering in `r4`. Emulated hardware behavior and rendering settings are preserved.

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

## Fork migration (`1.4.0-r2`)

Revision `r2` moves the existing renderer changes into `monofuel/melonDS` and
the two archive-build fixes into `monofuel/melonds-ds`. Both forks now expose
the work on their default `master` branches. The ebuild pins engine commit
`9cee6d4936cf70c677be9ee253650d6f1ecf417a` and wrapper commit
`a4c263700dde5b2d4cd4af714a1b3e8a05708cba`; the engine pin is also contained
in the history-preserving master merge. No new optimization is introduced.

The effective renderer source matches packaged `r1` exactly. The wrapper's
build files also match after accounting for the changed engine URL/pin. The
fork's ARM64 test passes all 6.4 million reference pixels. Both cores produce
identical complete video/PCM sequences in all three scenes, with 30 warmup
and 120 checked frames. Flags, other dependencies and open-demo PGO training
remain unchanged.

Five alternating 360-frame runs per scene/build on the DS Plus, using both GPU
displays and silent null audio, show equivalent performance:

| Scene | r1 ms / speed | r2 ms / speed | Throughput change |
| --- | ---: | ---: | ---: |
| Overworld 1 | 20.4189 / 81.861% | 20.4344 / 81.799% | -0.076% |
| Overworld 2 | 19.6389 / 85.112% | 19.6256 / 85.170% | +0.068% |
| Inventory | 16.8072 / 99.452% | 16.8400 / 99.258% | -0.195% |

The migration gate is no repeatable overworld regression exceeding 1%, plus
matching output. These differences pass; they are not evidence of a new speedup.
The packaged core SHA256 is
`6d0d304dee9700e4a9d85149ea504177219481c7fddfdc7d4a43e5fb9ca51664`.
Future performance changes belong in the forks, followed by new ebuild commit
pins and fresh correctness/performance comparisons.

## Further CPU experiments against r2

Fresh r2 profiles still show a busy emulation thread and a busy 3D worker.
A player profile attached after its `Presentation:` startup marker records
5.796 seconds of core-thread CPU and 4.491 seconds of 3D-worker CPU over a
six-second window, with 0.553 seconds on the frontend thread. Waiting for the
marker matters: an earlier attachment also captured initial state/identity
decoding and hashes, which are not steady gameplay costs.

Three independent GCC/open-demo-PGO rebuilds preserve all three video/PCM
sequences but do not justify promotion:

| Candidate | Headless overworld 1 / 2 gain | Player overworld 1 / 2 gain |
| --- | ---: | ---: |
| Inline the unchanged JIT block lookup into its callers | +0.193% / -1.047% | -1.417% / +0.424% |
| NEON-copy groups proven unchanged in regular color-effect mode zero | -2.376% / -3.178% | -3.077% / -2.409% |
| Extend that classifier to regular alpha mode | +1.408% / -0.550% | -0.135% / -1.438% |

The JIT lookup symbol disappears from the compiled candidate as intended;
removing that call does not establish a useful throughput gain. The pixel
classifier passes four million scalar-reference cases, but correctness alone
does not make it faster. These three candidates are rejected.

These exploratory comparisons use three alternating 360-frame repeats per
scene/mode. Player overworld 1 uses two clean paired repeats: the second round
is excluded because standalone unit compilation overlapped it. Raw logs are
retained. No promotion claim relies on the contaminated round.

Inspecting the saved GPU registers also shows why mode-zero specialization
does not cover the main display: both overworld states have engine A
`BlendCnt=0x214C` (regular alpha mode). Engine B is `0x0000` / `0x2880` in the
two states. These are snapshots, not a count of modes throughout gameplay.
The second scene also has engine B in brightness mode with no primary targets,
so limiting the shortcut to modes zero/one misses ordinary unchanged pixels.

The final prototype handles untargeted ordinary pixels across all four modes,
plus opaque 3D where normal effects cannot change it. Sprites, translucent 3D
and other affected pixels retain the scalar compositor. Keeping a single scalar
fallback call site also avoids duplicating that loop. Its reference test covers
four million randomized pixels and exhaustive flag/mode/primary-target cases.
All three video/PCM sequences match. In three paired 360-frame runs it gains
**1.876% / -0.271% headless** and **2.533% / 1.137% in the player**; uncapped
inventory gains 4.593%. These prototype results justify testing a real package,
not claiming full speed.

### Packaged r3 result

The actual Portage package uses engine commit
`af1e4a005e3478be1d9327f6aedb46fd0b2e9e2a` and wrapper commit
`b980e76fc90f890f17a76ff75e6da42eff78caca`. It passes both ARM64 reference tests,
native package/dependency checks and all three video/PCM comparisons. The
compiler, dependency versions, PGO inputs and renderer settings are unchanged.

Two independent alternating five-repeat player comparisons give **1.576% /
1.343%**, then **1.544% / 1.261%** overworld gains. The pooled result is:

| Scene | r2 ms / speed | r3 ms / speed | Throughput gain |
| --- | ---: | ---: | ---: |
| Overworld 1 (10 pairs) | 20.5569 / 81.311% | 20.2411 / 82.580% | +1.560% |
| Overworld 2 (10 pairs) | 19.5819 / 85.360% | 19.3303 / 86.471% | +1.302% |
| Inventory (5 pairs) | 16.8028 / 99.478% | 16.8267 / 99.337% | -0.142% |

This package does **not** meet the earlier 2% screening target. It is adopted
as a smaller baseline improvement because both independent blocks reproduce
gains in both overworlds, with exact output and a small, conservative selector.
Do not describe it as passing the 2% target or closing the full-speed gap.
Core SHA256:
`c823037517a2f52264c0e8ca052b8d3be2698a5370173988ff8c5803409419b6`.
Portage installation and all three migrated-state player smoke tests pass;
original saves and previous cores remain preserved. Normal audio/gameplay
acceptance remains a separate human check.

### Scanline-cache experiment against r3

A fresh steady player profile records 5.770 seconds of emulation-thread CPU,
4.507 seconds of 3D-worker CPU and 0.535 seconds of frontend-thread CPU over
six seconds. Listed 2D routines account for 11.06% of sampled user CPU work;
this is not a measurement of time that caching could remove.

An always-render diagnostic measures reuse of complete mode-zero 2D scanlines.
Its conservative key covers registers, windows, sprite/mosaic results, background
palette and changed VRAM contents. Sprite indices alone are insufficient:
`InterleaveSprites` resolves their colours later. Comparing the entire sprite
palette gives zero overworld hits because unused colours change. Comparing only
colours used by visible sprites predicts **27.78% / 50.13%** bottom-screen row
reuse, with no false predictions across 330 frames per scene. These diagnostic
builds do not skip drawing, and their timings are not performance results.

A separate prototype actually reuses those outputs, preserves window/mosaic
side effects, and invalidates its cache on reset/state import. It receives fresh
open-demo PGO and matches all three video/PCM sequences (30 warmup +120 checked
frames). Three alternating 360-frame pairs per scene/mode show:

| Scene | r3 player ms / speed | Cache player ms / speed | Player throughput change | Headless change |
| --- | ---: | ---: | ---: | ---: |
| Overworld 1 | 20.2056 / 82.725% | 21.4648 / 77.872% | -5.867% | -5.049% |
| Overworld 2 | 19.2843 / 86.677% | 19.8250 / 84.313% | -2.728% | -3.409% |
| Inventory | 16.8463 / 99.221% | 16.7815 / 99.605% | +0.386% | +5.528% |

**Rejected; not installed.** The static inventory benefits uncapped, while both
overworlds regress. CPU frequency stays at 1.992 GHz in the recorded samples;
the device runs no concurrent compilation/probes during timing. This rules out
this cache design, not every possible CPU optimization. The installed r3 core,
launcher and original saves remain unchanged.

### One-scanline-ahead sprite-worker experiment against r3

The existing schedule rasterizes sprites one scanline ahead. A private prototype
moves that work for both 2D engines onto one additional sleeping worker, while
CPU emulation advances the next line. The owner thread makes flattened OBJ VRAM
coherent and snapshots four mutable registers plus 1 KiB OAM per enabled engine.
The worker reads only these inputs and the stable flattened sprite memory.
Palettes, horizontal mosaic, windows and compositing remain on the owner thread.
Waits protect consumption, subsequent memory updates, reset, state operations
and destruction. No additional emulated frame/scanline delay is introduced.

The prototype uses current r3 sources and a fresh four-open-demo PGO build.
Both its threaded mode and an identical serial-snapshot control match r3's
complete video/PCM sequences in all three scenes (30 warmup +120 checked frames).
Both also match r3 in a separate lifecycle test that exports/restores state
every 17 frames and resets before alternate restores, for 120 checked frames
per scene. This exercises state/reset boundaries; it is not a speed measurement.
Three alternating 360-frame runs per scene/mode exclude hashing from timing:

| Scene | r3 player ms / speed | Serial-snapshot player ms / speed | Sprite-worker player ms / speed | Worker change vs r3 |
| --- | ---: | ---: | ---: | ---: |
| Overworld 1 | 20.3074 / 82.310% | 20.5926 / 81.171% | 21.3120 / 78.430% | -4.714% |
| Overworld 2 | 19.2074 / 87.024% | 19.6704 / 84.976% | 20.3620 / 82.090% | -5.671% |
| Inventory | 16.8093 / 99.440% | 16.8120 / 99.423% | 16.8139 / 99.413% | -0.028% |

Headless worker throughput regresses **5.763% / 6.716% / 9.020%** respectively.
Against the identical serial-snapshot artifact, threading adds about
**0.72 / 0.69 ms** per overworld player frame. The serial control itself is
1.39% / 2.35% slower than r3 in the player; that difference also includes source
layout and fresh PGO, so it is not an isolated measurement of OAM-copy cost.
All end-of-run CPU samples remain 1.992 GHz; recorded temperatures are
47.8–56.7 degrees C. Automated playback is silent, with independent save copies.

A separate six-second player profile confirms the additional scheduling work:
main-thread context switches increase from **1,923 to 23,829**, and the new
sprite worker records **51,226** switches. The main/sprite/3D threads consume
5.613/1.186/4.268 seconds of CPU in that window, versus 5.796/4.653 seconds
for r3's main/3D threads. These fixed-duration profiles run at different game
speeds; their CPU totals are not per-frame savings. Their timings are excluded
from the capacity comparison above.

**Rejected; not installed.** Parallelizing this small pass at scanline granularity
does not justify its synchronization and snapshot overhead. This does not rule
out coarser parallelism or faster sprite selection/rasterization. The private
candidate SHA256 is
`988effd449e5dfeeea0e19d53ac531e1e2761e371a23dbe3c7cd37976ed3cc92`.
Installed r3, public engine/wrapper sources and original saves remain unchanged.

### Sprite selection and 2D PGO controls against r3

An ARM64 little-endian prototype selects visible sprites eight at a time with
NEON, preserving OAM order and leaving the original rasterizer and portable
path intact. It reads current OAM each line, with no cache or worker. Native
tests compare **172,183,552** scalar visibility predicates, ordered lists and
output canaries, including wrapped Y, signed X boundaries, shapes and affine
double sizes. A fresh four-open-demo PGO build preserves all three video/PCM
sequences (30 warmup +120 checked frames).

A separate control restores original r3 `GPU2D_Soft.cpp` and disables profile
use only for that translation unit. All other trained objects remain; the
NEON-selection change is absent. Its three video/PCM comparisons also pass.
Each candidate receives its own three alternating 360-frame pairs per
scene/mode, with no hashing/profiling inside the timing comparisons:

| Candidate | Headless overworld 1 / 2 change | Player overworld 1 / 2 change | Decision |
| --- | ---: | ---: | --- |
| NEON sprite selection | +1.195% / +1.690% | +0.856% / +0.420% | Not promoted; no material player gain established |
| Disable PGO only for original 2D renderer | -1.687% / -2.055% | -1.877% / -3.019% | Rejected |

Culling improves uncapped inventory 2.239%, while paced player inventory changes
-0.237%. The PGO control changes them -2.889% / -0.209%. These are independent
comparisons, not changes to add together. The control does not establish that
the existing demos are the best possible training mix; it shows that discarding
their 2D profile is not a useful shortcut. Installed r3 and original saves remain
unchanged.

Candidate SHA256 values:

- Culling: `087ea9b797786b533056358ebd7f83f78f5e122d477b0d0ae4bcf1abd1b5e573`.
- Original 2D without PGO: `8013defe319bf763f1fb29c6edc1635eccb41ae10bf430fe030dd928c220c4ce`.

A separate six-second r3 player hardware-counter sample records main/3D-worker
IPC **0.666 / 0.864**, branch-miss ratios **5.0% / 2.6%**, and L1 data-load-miss
ratios **1.3% / 2.9%**. These describe CPU execution, not removable frame time.
They do not establish a RAM-bandwidth bottleneck; DDR bandwidth is unmeasured.
The generic cycles alias also attempts an unsupported Rockchip DDR event;
the ARM CPU cycles/instruction counters themselves work.

### Main-thread 2D work and batching feasibility

A diagnostic based on r3 times the original scanline and sprite routines,
their nested VRAM-coherence work, and the actual 3D semaphore waits. It changes
no rendering decisions. All three video/PCM sequences match r3 (30 warmup +120
checked frames). Separate 360-frame headless/player runs exclude hashing;
the table averages frames 30–359 of the player runs.

| Scene | Scanlines | Sprites | Nested coherence | Nested GetLine | 2D residual |
| --- | ---: | ---: | ---: | ---: | ---: |
| Overworld 1 | 3.5294 ms | 1.7858 ms | 0.4011 ms | 0.1080 ms | 4.8061 ms |
| Overworld 2 | 3.5042 ms | 1.7132 ms | 0.3784 ms | 0.1007 ms | 4.7384 ms |
| Inventory | 2.9859 ms | 1.1990 ms | 0.3341 ms | 0.0854 ms | 3.7653 ms |

Residual is scanlines + sprites − coherence − GetLine. It includes diagnostic
overhead and is an upper bound on work a 2D worker could take over, **not a
measured frame-time saving**. The build makes 3,074 timestamp reads per frame;
clock calibration estimates about 0.17–0.22 ms for those reads in total, and
there is additional bitset bookkeeping and a different trained code layout.
Actual GetLine semaphore waits average only 0.0609 / 0.0568 / 0.0495 ms;
the frame-end 3D wait is below 0.001 ms in all three scenes.

Flattened 2D VRAM requires updates on an average 0.445 / 0.230 / 0.000 scanlines
per frame, with a maximum of one in the overworlds. Only the engine-A BG set
changes; these sequences contain no display capture. A separate write probe
finds palette writes on every visible line, but snapshotting the palette removes
that dependency: no other observed write interrupts the visible interval in
120 checked frames per scene. This supports testing coarse batches with immutable
register/palette/OAM snapshots and draining before flattened VRAM changes.
It does not establish safety for untested games or mid-frame effects.

The main emulation thread remains the critical path. A separate six-second
sample uses 5.796 seconds of main-thread CPU, 4.653 seconds of 3D-worker CPU
and 0.545 seconds of frontend CPU: about 1.8 cores of a four-core device.
Moving enough 2D work onto an idle core could help; the earlier per-scanline
sprite worker shows why queue and synchronization costs must be measured.

### Coarse 2D worker experiment against r3

A private prototype queues complete HBlank records in batches of 16 through a
32-slot ring. The main thread keeps register latches and VRAM coherence at their
original emulated times. The worker uses shadow 2D engines, copied register/
palette/OAM data and stable flattened VRAM. It drains before cache changes,
3D restarts, state operations and presentation; capture and raw VRAM/FIFO display
modes render inline. Window carry is merged before saving state.

Fresh four-open-demo PGO, three alternating 360-frame pairs per scene/mode,
same r3 control and player, no timed hashing:

| Scene | r3 headless speed | Batched headless speed | r3 player speed | Batched player speed |
| --- | ---: | ---: | ---: | ---: |
| Overworld 1 | 88.94% | 100.80% | 82.74% | 95.69% |
| Overworld 2 | 95.24% | 115.42% | 85.52% | 98.50% |
| Inventory | 173.40% | 229.15% | 99.42% | 99.43% |

Full-player overworld times fall **20.2028→17.4685 ms** and
**19.5463→16.9694 ms**, throughput gains of **15.65% / 15.19%**. The prototype
has full-speed headless capacity in these short tests, but **normal playback
is not yet full speed**. Inventory remains intentionally paced.

All three complete video/PCM sequences match r3 at batch sizes 0, 1, 4, 8 and
16. A host differential matrix covers raster changes, VRAM remapping, capture,
window carry, state operations, resets and thread settings: 100 seeds ×12
frames plus named cases, with matching frame and full-GPU-state hashes across
all tested batch sizes, threaded/serial modes and randomized worker pacing.
Native ARM fixtures also match at batch sizes 0/1/8/16 and with threading
disabled (10 seeds ×4 frames plus the named cases).

The initial host mismatch came from an upstream uninitialized `CaptureEnable`
flag, not the batching implementation: the first divergent state differed in
that one byte, then unintended capture changed VRAM. The harness now sets a
known initial flag and poisons allocations identically in both builds. This
makes inputs repeatable; it does not detect every uninitialized read. Both
reference and candidate report existing main/3D lifecycle races under host
ThreadSanitizer. No report involves the new 2D worker in the small checked runs;
this is not an exhaustive race-free result. Mid-frame lifecycle cases keep 3D
off BG0 because the reference has nondeterministic 3D scanline-token behavior.

Two further alternating pairs compare batch sizes 4/8/16. Player speeds are
**96.03/96.09/96.38%** in overworld 1 and **98.67/98.55/98.63%** in overworld 2;
smaller batches provide no clear playback win. The same artifact forced inline
reaches only 80.70% / 84.77%, so snapshots alone are not the improvement.

Artifact SHA256: `eb1ab307c76044d12b222dc5b0e803e99a5e41710cfa956dfa40a439f8fd1149`.
The [engine implementation and fixtures](https://github.com/monofuel/melonDS/commit/4d22164dc9843fd1ef8f3e87b4782463b39b9f39)
are published; wrapper commit `a2c790780931e40502ed1b54eb53ae7f8a7253dc`
pins that engine for the r4 recipe. Installed r3 and original saves remain
unchanged during the following comparisons.

#### Packaged r4 result

The r4 recipe pins engine `4d22164dc9843fd1ef8f3e87b4782463b39b9f39` and wrapper
`a2c790780931e40502ed1b54eb53ae7f8a7253dc`, with unchanged compiler settings,
dependencies and open-demo training. It builds from the checksummed public
archives. Three alternating 360-frame pairs against installed r3 give:

| Scene | r3 player ms / speed | r4 player ms / speed | Throughput gain |
| --- | ---: | ---: | ---: |
| Overworld 1 | 20.4759 / 81.63% | 17.1694 / 97.35% | 19.26% |
| Overworld 2 | 19.3204 / 86.52% | 16.9417 / 98.66% | 14.04% |
| Inventory | 16.8185 / 99.38% | 16.8130 / 99.42% | 0.03% |

Uncapped r4 capacity is **99.65% / 116.47% / 230.19%**. Overworld 1 still lacks
consistent full-speed headroom; the goal is not complete. All three full
video/PCM comparisons match r3. The actual binary package is installed, its
source notices/API/dependencies checked, and all three migrated states pass
silent 60-frame smoke tests through the normal wrapper. Representative manual
gameplay/audio acceptance remains pending.

Installed core SHA256: `7561e16dd677d7b28c92a1c512499eeaab62a7f191312deea08fac7bc541ef84`.
The original r3 saves remain unchanged; active slots are re-exported into
`monomelon-batched-lost-in-blue`. The before-batching launcher retains r3 for
rollback. The temporary cross-build configuration now selects the target
`strip`/`objcopy` explicitly; package build 2 fixes the first build's host-strip
QA warning without recompiling the trained core.

#### Follow-ups against the batched control

Each candidate receives fresh four-open-demo PGO, all-three-scene video/PCM
comparisons and three alternating 360-frame timing pairs per scene/mode.

| Candidate | Headless OW1 / OW2 gain | Player OW1 / OW2 gain | Decision |
| --- | ---: | ---: | --- |
| Add deferred perspective division | +3.090% / +0.430% | +1.034% / +0.016% | Retained privately; small OW1 gain needs confirmation |
| Increase ring capacity 32→64 | +1.054% / +3.125% | +0.112% / +0.005% | Not promoted; no material playback gain |
| Contiguous framebuffers and direct vertical-layout callback | +0.280% / +1.738% | −0.339% / +0.027% | Not promoted; no playback gain |

The direct callback skips wrapper staging clears/copies only when the two
contiguous screens exactly match an unrotated, unscaled, gap-free top/bottom
layout with no cursor; other layouts retain staging. It improves uncapped
inventory 5.293%, but paced player inventory only 0.072%. This is useful evidence
about copying costs, not a reason to add that path to the release now.

#### CPU counters after batching

Separate post-warmup, 360-frame headless profiles use named Cortex-A55 PMU
events. Main/3D/2D task-clock averages in overworld 1 are approximately
**14.63 / 15.46 / 5.07 ms/frame**, versus r3's main/3D **18.76 / 15.63 ms**.
Overworld 2 is **13.33 / 12.59 / 4.90 ms**, versus **17.64 / 12.79 ms**.
These collection windows include shutdown/pipeline cleanup and kernel time;
they are approximate thread costs, not exact isolated render durations.

Overworld-1 main/3D/2D IPC is **0.601 / 0.888 / 0.981**. Frontend-stall counts
are **31.4% / 2.9% / 5.2%** of user cycles, backend stalls
**24.2% / 39.5% / 27.6%**. Here *frontend* means CPU instruction delivery,
not mono-retro-player. These counters do not assign every stall to a particular
cache or instruction, and do not establish a DDR-bandwidth limit.

This supports investigating both the remaining main-thread work and 3D
rendering, rather than expecting more 2D queue tuning to close the gap.
The as-found governor is `performance`; frequency history records only
1.992 GHz. Both display modes are 1024×768, clock 62.770 MHz with totals
1304×800 (about 60.17 Hz), above the game's nominal rate. No clock, governor
or display-mode changes are made.

### Deferred perspective division against r3

A private 3D candidate delays perspective-factor calculation until a pixel
passes depth testing. Shadow loops avoid the unused calculation where their
depth mode permits. The arithmetic itself is unchanged. A native test checks
675,013,042 interpolation cases with no failures; all three game video/PCM
sequences also match. The candidate receives fresh four-open-demo PGO.

Three alternating 360-frame pairs give player throughput changes of
**+0.641% / −0.469% / −0.154%** for overworld 1 / overworld 2 / inventory.
There is no demonstrated player win, so it is not installed.

A separate pair of alternating CPU profiles per overworld measures the 3D
thread's task-clock over 360 frames. Mean CPU time falls from **15.3304 to
14.8622 ms/frame** in overworld 1 and **12.4997 to 12.2320 ms/frame** in overworld
2 (about 3.1% / 2.1% less CPU time). Collection excludes warmup and includes
pipeline completion/cleanup, so these are approximate thread costs. This adds
3D headroom but does not shorten the current main-thread critical path; it may
be worth combining with a later main-thread improvement.

### GLES renderer feasibility

A [standalone surfaceless probe](https://github.com/monofuel/melonDS/blob/master/tests/monomelon/probe-compute-gles.cpp)
compiles and links seven representative existing compute shader variants on
the actual Mali-G52/Panfrost, GLES 3.1 Mesa 26.1.8. It adapts the GLSL version and
precision declarations, enables supported texture-buffer and implicit-conversion
extensions, and makes two integer return casts explicit. The shader algorithms
are unchanged. The device reports 256 invocations/group, 32 KiB shared memory
and eight compute SSBO blocks.

This does not dispatch GPU work, render a game, or establish accuracy or speed.
The existing engine/wrapper request desktop OpenGL, and the player currently
lacks libretro hardware-context support. A GLES renderer port and host integration
remain necessary. Shader compilation is a useful starting point, not a working
GPU emulator.

A follow-up surfaceless probe also compiles/links all seven display shader
pairs: layer preprocessing, sprite preprocessing/rendering, 2D compositing,
final output, capture and capture downscaling. It changes GLSL 140 to ES 310,
declares high precision for the relevant numeric/sampler types, enables the
advertised implicit-conversion extension and assigns explicit fragment-output
locations. The first run identifies one missing signed-sampler precision
declaration; adding it gives **14/14** passes including the seven compute variants.
The shader algorithms remain unchanged.

The device advertises `GL_EXT_draw_buffers_indexed` and reports 64 KiB uniform
blocks, 105 uniform-buffer bindings, eight draw buffers and 16384-pixel maximum
texture dimensions. Remaining integration includes desktop-only API calls
(`glDrawBuffer`, `glFramebufferTexture`, fragment-output binding), extension
entry points for indexed colour masks/texture buffers, GLES context negotiation
in the wrapper and a hardware-render context in the host. Advertised extensions
and linked shaders alone do not prove those paths work.

### Native GLES experiment (not installed)

An isolated prototype now builds the actual core for GLES 3.1 and renders Lost
in Blue through a small Nim surfaceless-EGL host. It uses pinned r3 source bases
and private source overrides; it is not an available ebuild or a change to the
normal player. This feasibility build has **no PGO**, unlike installed r3.
The host waits for actual GPU completion, separates shader-compilation frames
from emulated frames and rejects software fallback. Its normalized software
video/PCM hashes match the existing benchmark in all three saved scenes.

Getting real frames required more than the shader probes:

- Fix GLES 3.1 feature/imported-target declarations and extension entry points.
- Use GLES-compatible framebuffer operations and explicit output locations.
- Convert desktop reversed-5551 uploads to supported GLES 5551 without losing
  colour/alpha bits; convert RGBA8 capture readback back to DS words. The pure
  packing arithmetic passes all 65,536 possible input words.
- Restore the three tile-storage bindings before depth/compositing, including
  empty scenes. A native backtrace placed the first crash inside Mesa at that
  dispatch; rebinding the buffers fixes the observed crash.
- Fix final six-to-eight-bit colour expansion: `(c << 2) | (c >> 4)`, rather
  than `c >> 6`, which discarded the replicated low bits. This removes most
  of the initial colour differences, but does not establish output equality.

Three alternating 180-frame capacity runs per mode/scene, after 30 warmup
frames, exclude screenshot readback and hashing. GPU runs use `glFinish` per
frame, so they measure completed work rather than an expanding command queue:

| Scene | Installed r3 software ms / speed | Experimental GPU ms / speed |
| --- | ---: | ---: |
| Overworld 1 | 18.4706 / 90.496% | 30.6005 / 54.624% |
| Overworld 2 | 17.5036 / 95.495% | 27.3427 / 61.132% |
| Inventory | 9.5197 / 175.584% | 13.6909 / 122.090% |

These are **headless capacity**, not full-player measurements. The GPU column
uses the pre-colour-fix prototype; a post-fix profiling run remains about
54.5% in overworld 1. Single-run software controls using the same untrained
GLES-enabled core reach **83.11% / 89.76% / 162.47%**, also faster than the GPU
route. Do not attribute the whole difference to rendering: the installed
software control has PGO, and the experimental renderers do not.

The GPU's normal governor reaches its stock **800 MHz** maximum under load;
no clocks/governors are changed. A six-second post-fix GPU profile records
4.469 seconds of main-thread CPU, with additional GPU-completion waits.
This implementation adds meaningful CPU-side work as well as GPU work.

The untrained core's **software** mode preserves all three video/PCM sequences.
Its GPU mode does not: scene 1 PCM matches, while scenes 2/3 have PCM differences
with equal sample counts. RGB differences also remain after the colour fix;
scene 1's first checked frame differs at 538/1,444 pixels on its two screens.
Their causes are unresolved; no accuracy acceptance is claimed. These runs
bootstrap the GPU renderer before importing the test state, which is another
condition to investigate when comparing PCM.

**Not promoted.** This proves a GLES compute/display port can render on the
device; it does not provide a faster or validated replacement. The normal
launcher/player, installed r3 core and original saves remain unchanged. GPU
work remains possible, but this backend needs substantial performance and
accuracy work. The immediate focus returns to the software core's critical path.

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

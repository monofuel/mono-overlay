# monoMelon tweaks and performance

**Benchmark update, November 12:** slot 2 is now the river near the start and
slot 4 is a new ocean scene. Slot 1 remains the cliff and slot 3 the menu.
Monofuel reports cliff/menu feel full speed, with slowdowns around water.
The percentage tables below precede this update unless explicitly marked;
old slot-2 measurements are not river measurements. Fresh measurements follow.

## Current four-state measurements

The earlier r4 core is `7561e16dd677d7b28c92a1c512499eeaab62a7f191312deea08fac7bc541ef84`.
Two 240-frame repeats per state/mode, reversing scene order on the second pass,
give the following baseline. Automated playback uses copied saves, neutral
input and null audio; output hashing is separate from timed runs.

| State | Core ms/frame | Core capacity | Player ms/frame | Player speed |
| --- | ---: | ---: | ---: | ---: |
| Cliff | 16.9903 | 98.380% | 17.1479 | 97.476% |
| River | 19.5307 | 85.584% | 19.6396 | 85.109% |
| Menu | 7.2762 | 229.722% | 16.8333 | 99.298% |
| Ocean | 28.2101 | 59.252% | 28.6333 | 58.376% |

Player timings include pacing, so a result near 100% does not establish the
goal's **105% whole-pipeline capacity**. Separate named-thread Cortex-A55 PMU
captures identify the ocean's 3D worker as the bottleneck: about **27.7 ms/frame**
of task-clock, versus main **13.5 ms** and 2D **6.3 ms**. Thread times overlap and
include pipeline completion/cleanup; they must not be summed as frame time.
The 3D worker retires about one instruction/cycle, with roughly 35% backend
stalls. These counters do not establish memory-bandwidth saturation.

### Active-polygon row lists: private candidate

The original renderer tests every polygon against every scanline. Ordered
per-row lists avoid those rejected checks without changing rasterization.
Only about 4–5% of polygon-row pairs are active in these saved scenes.
The bounded list builder passes native ARM64 predicate/order/capacity tests,
and complete video/PCM hashes match r4 for 30 warm-up plus 120 checked frames
in all four states. This is sequence coverage, not universal accuracy proof.

Three alternating 240-frame pairs compare fresh four-open-demo-PGO builds:

| State | Control player speed | Candidate player speed | Player throughput gain | Candidate core capacity |
| --- | ---: | ---: | ---: | ---: |
| Cliff | 95.766% | 97.512% | 1.823% | 107.317% |
| River | 84.136% | 91.091% | 8.265% | 95.650% |
| Menu | 99.363% | 99.445% | 0.083% | 227.762% |
| Ocean | 58.120% | 59.429% | 2.252% | 60.286% |

Candidate core SHA256: `8e0861f19c2d1615d5d3b672d0b1d22e0df34bb59f607cbacd6e841872564010`.
It is not installed or published as a release. The river gain is useful, but
the ocean still needs a much larger reduction in 3D work. A coarse two-worker
3D-rendering candidate is measured below.

### Two-worker 3D rendering: private candidate

The existing 3D thread renders the upper half and a persistent helper renders
the lower half into private buffers. Each publishes finished rows for the 2D
consumer. Edge marking includes the neighbouring row, and any shadow/mask
polygon keeps the original single-worker path because stencil history crosses
rows. This changes CPU scheduling, not rendering quality.

Candidate SHA256: `4167cb9f086c96d4d7f0e566579294586f3ccf24ed4e6ffa13cbb3dac184ea0a`.
Fresh four-open-demo PGO, three alternating 240-frame pairs, no active-row-list
change in this candidate:

| State | Control player speed | Candidate player speed | Player throughput gain | Candidate core capacity |
| --- | ---: | ---: | ---: | ---: |
| Cliff | 94.905% | 95.303% | 0.420% | 106.169% |
| River | 84.361% | 97.087% | 15.086% | 111.785% |
| Menu | 99.232% | 98.939% | -0.296% | 227.269% |
| Ocean | 58.089% | 86.800% | 49.427% | 93.169% |

All four state sequences and all four open demos match control video/PCM
hashes. Native ARM64 synthetic tests compare serial, threaded and banded
output, both complete colour/depth/attribute layers, shadow sequences,
FrameIdentical and renderer lifecycle. Coverage does not prove every possible
emulated hardware transition.

Independent review finds a reachable older race when a POWCNT1 write disables
rendering while workers read latched state; the extra worker can make the two
bands disagree. A revised private candidate waits before that reset and
initializes FrameIdentical. Added tests use the GPU's actual installed renderer
for power-control, reset and save/load paths. They pass with the barrier and
fail when it is deliberately removed. The measured candidate above remains
uninstalled; these fixes are required before promotion.

A single-repeat core-capacity sweep of ocean split rows 64/80/96/112/128 gives
71.27/77.40/93.56/95.08/85.67%. Output hashes match for every tested split.
Thus moving the split alone has not closed the gap. Named-thread ocean
task-clock is approximately main/upper/lower/2D **14.09/11.39/15.72/5.04 ms**
per frame.

### Combined lists, lifecycle fixes and three workers

The combined two-worker build (`27534b50e67b045ca34e46301516fa7101cfdf837c99b37c54d80b4c46f74d6c`)
passes the new real-GPU lifecycle tests, four saved-state video/PCM comparisons
and four open-demo comparisons. Three alternating 240-frame pairs give player
**96.611/97.040/99.249/88.904%** for cliff/river/menu/ocean; its ocean control
is 57.958%. The full 2D integration fixture matches a control with the same
FrameIdentical initialization fix. Against the older uninitialized control,
one renderer-replacement frame differs consistently; applying only that
initialization to the control accounts for the difference.

A further candidate uses three persistent rendering workers with separate
buffers and line-ready semaphores, defaulting to bands 0–63/64–127/128–191.
It retains shadow fallback and all lifecycle fixes. Source and compiled hashes
match; synthetic serial/two/three-worker comparisons pass on x86-64 and native
ARM64, and a focused host race-detector run reports no warnings. All four
saved-state and open-demo video/PCM sequences match the r4 control.

Three-worker core SHA256: `1f5034655c6e631c363d35b10787bebe0e38c5dcac5a1a734b60ee434d272498`.
Three alternating 240-frame pairs:

| State | Control player speed | Three-worker player speed | Player throughput gain | Three-worker core capacity |
| --- | ---: | ---: | ---: | ---: |
| Cliff | 94.666% | 96.287% | 1.712% | 105.080% |
| River | 84.968% | 97.496% | 14.744% | 111.252% |
| Menu | 99.693% | 99.759% | 0.066% | 226.389% |
| Ocean | 57.741% | 89.886% | 55.673% | 100.956% |

These are separate batches from the two-worker comparison; small differences
between their reported speeds are not a paired estimate of adding a worker.
These private artifacts were not installed. The later r5 package combines the
validated changes with unequal bands, as measured below.

A separate 360-frame run after 30 warm-up frames enables the frontend's normal
video and audio capture, with no display or audio output:

| State | Mean ms | Median ms | 95th percentile ms | Maximum ms |
| --- | ---: | ---: | ---: | ---: |
| Cliff | 15.681 | 15.613 | 16.308 | 23.706 |
| River | 14.983 | 14.935 | 15.732 | 22.673 |
| Menu | 7.613 | 7.524 | 8.246 | 9.633 |
| Ocean | 16.145 | 15.578 | 19.108 | 25.402 |

The ocean's longer frames remain above the 16.715 ms playback budget. An
average core rate near 100% does not establish smooth playback or the required
105% whole-pipeline headroom.

### Unequal bands and remaining waits

The same three-worker binary supports validation at arbitrary band boundaries.
A sweep identifies rows **96/160** as a useful ocean candidate. Three alternating
240-frame pairs compare the original 64/128 split with 96/160; all four saved
video/PCM sequences match:

| State | Equal-split player speed | Unequal-split player speed | Player throughput gain | Unequal-split core capacity |
| --- | ---: | ---: | ---: | ---: |
| Cliff | 94.547% | 96.395% | 1.954% | 104.598% |
| River | 97.702% | 97.095% | -0.621% | 110.838% |
| Menu | 99.339% | 99.167% | -0.173% | 226.634% |
| Ocean | 89.880% | 93.693% | 4.243% | 111.551% |

The ocean benefits, while cliff core headroom remains marginal. This is a
runtime experiment; r5 later makes 96/160 the default. Neither result establishes
the full-speed goal.

A private three-worker diagnostic times only the emulation thread's 2D fence
and 3D frame-done waits. All four video/PCM sequences still match, and native
synthetic tests pass. With 96/160, its full-player cliff/ocean averages are:

| State | Core wall time including capture | 2D fence wait | 3D frame-done wait |
| --- | ---: | ---: | ---: |
| Cliff | 16.845 ms | 1.027 ms | 0.001 ms |
| Ocean | 16.299 ms | 1.450 ms | 0.001 ms |

The 2D fence can include waiting for 3D rows inside the 2D worker; it is not
all removable 2D computation. There are about 1.3/1.6 fences per frame here.
The remaining core elapsed time includes execution, callbacks and preemption.
Different warm-up windows, diagnostic logging and fresh PGO prevent attributing
the headless/player difference entirely to CPU contention. No diagnostic timing
is a measured saving.

### Packaged r5: parallel software rendering

`libretro-monomelon-1.4.0-r5` pins wrapper `e32810b0` and engine `b15171a3`.
It combines ordered active-polygon row lists, three persistent 3D workers with
96/160 row boundaries, shadow fallback and the renderer lifecycle fixes.
Compiler settings, dependencies and four-open-demo PGO are unchanged.
Fresh compilation uses 271 profile-use commands with coverage mismatches still
treated as errors. Native synthetic tests and four game/four open-demo video
and PCM comparisons pass; this covers those sequences, not every game feature.

Core SHA256: `e4dcf23c4178475e36bd439ba29447f6bae2012b5410d5b80abffdb790fd4be1`.
Three alternating 240-frame pairs against r4, using the current four states:

| State | r4 player speed | r5 player speed | Player throughput gain | r5 core capacity |
| --- | ---: | ---: | ---: | ---: |
| Cliff | 95.115% | 95.926% | 0.853% | 104.542% |
| River | 83.494% | 96.705% | 15.822% | 110.902% |
| Menu | 99.380% | 99.085% | -0.296% | 226.659% |
| Ocean | 58.095% | 92.762% | 59.673% | 111.229% |

The package is installed through Portage on the DS Plus. All four copied states
are migrated through the core's serialization API and pass silent 60-frame
smokes through the installed player. Original states/SRAM and the player binary
remain unchanged. Normal playback uses `monomelon-parallel-lost-in-blue` saves;
`mono-retro-lost-in-blue-before-parallel` retains the r4 core and its save folder.
Manual gameplay acceptance of r5 remains pending. Core-only capacity and paced
player speed do not prove the 105% whole-pipeline headroom requirement.

Private evidence: `monomelon-package-r5-20261112/native-evidence.tar` and
`results.txt`; verified pre-install backup `before-r5-backup.tar` has SHA256
`e015373d1ff5b6e2c6f2f4108a2e51e5a7fd2c45d5512b7f6bf89f63f46ada9c`.

### Follow-ups against parallel rendering

- Reserving CPU0 for the emulation thread while restricting other player workers
  to CPU1–3 gains 2.721% ocean throughput but loses 1.540% on the cliff across
  three alternating pairs. River changes -0.234%. Rejected as a global policy;
  no affinity setting persists.
- A private XBGR output candidate matches all four video/PCM sequences with
  both accepted native-format negotiation and rejected/standard fallback.
  Full-player ocean throughput improves only 0.962%, cliff changes -0.199%
  and river +0.582%; headless does not improve. Fresh PGO and training defaults
  differ, so this comparison does not isolate the pixel format alone. Not promoted.
- A native A55 copy microbenchmark checks bytes and guards for unaligned packed
  256×384 frames. Row memcpy averages about 100 microseconds/frame, one bulk copy
  97, inline NEON copy 114 and existing XRGB conversion 139. This isolates warm
  memory copying, not callback latency or whole-player performance. Saving roughly
  3 microseconds by combining rows is too small to prioritize over emulator work.

Evidence: `monomelon-water-scenes-20261112/affinity-evidence.tar`,
`monomelon-xbgr-20261112/native-evidence.tar` and
`monomelon-pixel-copy-20261112/native-results.log`, all private experiment roots.

### Scheduler and snapshot reuse experiments

Two independent private candidates use the same r5 source baseline and fresh
four-open-demo PGO. Both match all four current state and four open-demo video/PCM
sequences. Three alternating 240-frame pairs include frontend video/audio capture
in headless measurements and paired GPU displays with null audio in the player.
Each column below compares against that candidate's own interleaved r5 control.

| State | Scheduler core gain | Scheduler player gain | Snapshot core gain | Snapshot player gain |
| --- | ---: | ---: | ---: | ---: |
| Cliff | 1.024% | 0.168% | 0.889% | -0.480% |
| River | 0.118% | -0.652% | 0.443% | 0.349% |
| Menu | 1.813% | 0.728% | -0.373% | 0.206% |
| Ocean | -0.438% | 0.291% | 1.351% | -0.628% |

The scheduler caches the earliest active event and skips no-due-event scans,
retaining the original callback order and slice targets. Tests exercise actual
callbacks, cancellation/rescheduling, periodic events, sleep, reset, save/load
and 20,000 changing schedule/cancel/fire steps against the original scan's target.
The fixture also passes against unmodified r5. Candidate SHA256:
`bd77b6787cddef2ae360071b1581fd39a29c83ec5df64b35f5fb2c0997d6224f`.

The snapshot candidate reuses each consumed ring slot's palette/OAM bytes until
the existing dirty flags indicate guest writes, using generation counters.
It adds no shared-buffer lifetime or pool mechanism. Existing complete-frame and
serialized-state fixtures match r5 for batches 0/1/8/16, including mid-frame
writes, capture, renderer changes and state/reset paths. Candidate SHA256:
`692159f8f6294186955ad6cfe49b848c16b4f24df7ad09bf0b3b1d8151a09171`.

Neither provides a convincing overall player improvement; both remain private
and uninstalled. Small core-only gains do not justify claiming the playback gap
is closed. Evidence in the respective private `monomelon-scheduler-20261112`
and `monomelon-snapshot-20261112` roots includes `native-evidence.tar`,
`results.txt`, changed-source checks and build logs.

### Smaller batches and AArch64 dispatch tails

With r5's three 3D workers, a same-binary comparison of 2D batches 16 versus 8
gives the following result. Two alternating 240-frame pairs per state/mode;
all four video/PCM sequences match. This is a scouting result, not a changed
shipping default. The previous batching comparisons predate three-worker 3D.

| State | Batch-16 player speed | Batch-8 player speed | Player gain | Core gain |
| --- | ---: | ---: | ---: | ---: |
| Cliff | 95.458% | 96.179% | 0.755% | 1.131% |
| River | 97.535% | 97.252% | -0.291% | 2.630% |
| Menu | 98.809% | 99.273% | 0.470% | 6.885% |
| Ocean | 92.296% | 95.686% | 3.673% | 3.204% |

A separate AArch64 JIT candidate emits shared dispatch tails for ARM9/ARM7.
They retain each existing block boundary, save flags, account signed cycles,
reload the current deadline and re-read the normal tagged block table. IRQ/halt,
cache misses and region changes return through the original C++ path. There is
no larger-block or direct-link invalidation shortcut. A private validation
control restores the original exit path. Fresh four-open-demo PGO is unchanged.

Candidate SHA256: `14438180f194f4841c8370f2ffa936a97ae528431d42ac77c1df66242c7d17f4`.
All four saved-scene and four open-demo video/PCM sequences match r5. Three
alternating 240-frame pairs, with the normal 16-line batching:

| State | r5 player speed | Dispatch player speed | Player gain | Core gain |
| --- | ---: | ---: | ---: | ---: |
| Cliff | 94.800% | 96.798% | 2.107% | 1.315% |
| River | 97.063% | 97.275% | 0.218% | 0.677% |
| Menu | 98.865% | 99.347% | 0.487% | 1.984% |
| Ocean | 93.171% | 93.847% | 0.725% | 0.672% |

Synthetic tests execute the actual generated tails under QEMU and natively on
the DS Plus, covering ARM9/ARM7, ARM/Thumb, high guest addresses, cycle deadlines,
changed targets, pending IRQ handoff, invalidated/wrong-tag entries, region exits,
signed cycles, flag publication and a forced block-cache reset. Both the original
and new paths are exercised through the real CPU execution loop. The first test
harness omitted `NDS::Reset()` and crashed even on the original path; adding the
required reset fixes it. The retained failing logs document a harness setup
error, not a skipped production failure. The resulting native test binary has
SHA256 `e80fd3803e3a98eb4547ae47e7377ea5db7ed8bad9303c8fe1f4ec28e32b96f9`.

Both experiments remain private and uninstalled. Evidence is in
`monomelon-snapshot-20261112/{batch-evidence.tar,batch-results.txt}` and
`monomelon-dispatch-20261112/{native-evidence.tar,results.txt,unit-evidence.tar,native-unit.log}`.
Combining compatible candidates requires a fresh measured build; adding these
separate percentage gains is not evidence of combined performance.

### Combined CPU candidate and presentation experiments

Backdrop-only palette caching is now tested, including full 32-bit writes at
offsets 0/0x400. A 4,096-step snapshot fixture covers reused slots, unchanged and
mixed writes, reset, state loading and renderer replacement. Deliberately copying
only 16 bits fails the byte comparison. Complete-frame/state fixtures and all
four game/four open-demo video/PCM sequences match control. Three paired runs
show no useful overall player gain: cliff/river/menu/ocean change
**-0.998/-0.371/-0.025/+0.474%**. This candidate remains uninstalled.

A fresh build combines scheduler caching, backdrop/OAM snapshot reuse, shared
AArch64 dispatch tails and eight-line 2D batches. Three alternating 240-frame
pairs, with capture callbacks included in uncapped core timing:

| State | r5 core capacity | Combined core capacity | r5 player speed | Combined player speed |
| --- | ---: | ---: | ---: | ---: |
| Cliff | 102.371% | 107.889% | 96.457% | 97.638% |
| River | 109.531% | 115.878% | 96.891% | 97.535% |
| Menu | 221.559% | 234.688% | 99.093% | 99.717% |
| Ocean | 109.909% | 115.157% | 93.243% | 94.008% |

Core SHA256: `7169cfe8602d14316551a0fc01db4b074e785d701aa525c47ef91a426ed675f7`.
All four game/four open-demo output sequences match, and native ARM64 snapshot,
scheduler and emitted-dispatch fixtures pass. One cliff core run reaches only
103.861%; the mean does not prove a consistent 105% margin. Player results still
miss full speed. A later callback-reentrancy test finds stale scheduler minima
if a callback queries the target before another due event is removed. Invalidating
the cache on every removal and sleep-time adjustment fixes the regression; the
old implementation fails that test. The artifact above predates that fix and
must not be promoted. A fresh corrected build is being validated separately.

Private Windy experiments keep one paired atomic flip pending while rendering
the next frame into a free GBM buffer. They never release old scanout before both
controllers finish, and lock at most three buffers. Timing includes the final
physical flip, using verified monotonic DRM timestamps rather than returning early
and ignoring that last wait. Two alternating 240-frame runs with the combined
core give these per-run ranges:

| State | Render-ahead, normal GPU governor | Render-ahead, supported maximum GPU clock |
| --- | ---: | ---: |
| Cliff | 97.654–97.982% | 98.325–98.392% |
| River | 98.037–98.171% | 98.056–98.205% |
| Menu | 99.562–99.585% | 99.619–99.851% |
| Ocean | 96.172–97.845% | 97.824–98.005% |

These are paced, short-run results, not 105% processing-capacity measurements.
Changing the GPU governor does not consistently solve the gap. The experiment
temporarily selects the supported 800 MHz performance policy, then restores
`simple_ondemand`; it changes no voltage, supported clock limits or installed
configuration. The installed r5 core, player and live saves remain unchanged.

Evidence: private `monomelon-backdrop-20261112`,
`monomelon-cpu-combined-20261112` and `monomelon-present-20261112` roots, including
`native-evidence.tar`, `results.txt`, `ahead-native-evidence.tar` and
`ahead-policy-results.txt`. Fresh sources and open-demo PGO are used for each
CPU build; percentages from separate batches are not added together.

### Corrected combination and long-frame diagnosis

The corrected scheduler combination builds as
`e56d462032276f9fa2e786866b7e20d8e0cef0faa0a6ef70b8d4ea7bb1029106`.
All four game and four open-demo video/PCM sequences match r5. Assertion-enabled
snapshot, scheduler and actual generated-dispatch tests pass under QEMU and
natively. Three alternating 240-frame pairs use the same private render-ahead
player and normal GPU governor for both cores:

| State | r5 core capacity | Corrected core capacity | r5 player speed | Corrected player speed |
| --- | ---: | ---: | ---: | ---: |
| Cliff | 103.546% | 109.298% | 97.452% | 98.015% |
| River | 109.358% | 114.218% | 97.750% | 98.008% |
| Menu | 220.657% | 233.716% | 99.745% | 99.651% |
| Ocean | 109.718% | 115.069% | 95.386% | 97.989% |

Player columns include startup and the final physical flip; they differ from
raw loop-only results. The core gain is 4.4–5.9%, but these measurements still
do not establish whole-pipeline headroom. Nothing new is installed.

A private player now records per-frame monotonic timestamps for core work,
reply collection, next-frame dispatch and presentation. After the first 30
frames, core submissions average near the native cadence, while recurring long
frames remain. In the ocean control, the 95th-percentile CPU/handoff service
estimate is **19.84–20.55 ms**, and reply collection can take several milliseconds.
This estimate excludes some foreground dependencies; it is not the goal's
whole-pipeline capacity measurement.

Two reversed-order tests temporarily raise only the frontend thread's priority
from nice 0 to -10 after initialization. Ocean handoff p95 falls from
**3.17–3.82 ms to 0.26–0.36 ms**, but core spikes remain and total results vary.
Raising both the frontend and emulation thread also leaves long frames. All
priority changes end with their private processes; no service policy is changed.

Cliff frames 34, 35, 44 and 149 repeatedly take longer than surrounding frames;
frame 44 takes roughly 23 ms across priority variants. Ocean frame 36 also
repeats as a long frame. Explicit `perf record --clockid mono` allows samples
to be aligned with these intervals. Samples include JIT compilation in cliff
spikes, but are too sparse to assign the whole delay to it. A following trace
separates emulation-thread CPU work from off-CPU time (after 30 warm-up frames):

| State | Mean core wall time | Mean thread CPU time | Mean off-CPU time | Reproducible spike: wall / CPU |
| --- | ---: | ---: | ---: | ---: |
| Cliff | 15.416 ms | 14.272 ms | 1.144 ms | Frame 44: 23.194 / 21.984 ms |
| Ocean | 15.316 ms | 13.140 ms | 2.176 ms | Frame 36: 23.912 / 22.479 ms |

Thus scheduling/fence waits matter, but do not explain the largest repeatable
spikes: those consume substantially more CPU too. Off-CPU time does not distinguish
preemption from renderer fences. The next diagnostics should measure compilation
cost and fence time within these specific frames before choosing a code change.
The earlier default-clock profile must not be aligned to CLOCK_MONOTONIC traces.

Another private experiment removes the explicit `glFinish`, retaining buffer
ownership and paired flips. The checked Linux 7.0.2
[GEM plane helper](https://github.com/gregkh/linux/blob/v7.0.2/drivers/gpu/drm/drm_gem_atomic_helper.c)
and [atomic helper](https://github.com/gregkh/linux/blob/v7.0.2/drivers/gpu/drm/drm_atomic_helper.c)
provide implicit render-fence synchronization. This scout shows no consistent
solution to the gap; the normal presenter is unchanged. It is not a display
accuracy acceptance test.

Evidence: `monomelon-cpu-combined-fixed-20261112/{native-evidence.tar,results.txt,physical-player-results.txt}`
and `monomelon-present-20261112/{trace-fence-evidence.tar,trace-results.txt,priority-evidence.tar,priority-results.txt,trace-profile-evidence.tar}`.
Per-thread CPU measurements are in `cpu-time-evidence.tar` and `cpu-time-results.txt`
under the same presentation experiment root.
Automated audio stays silent, and installed binaries/save checks pass after
each batch. Warmed averages, headless capacity and a scheduling improvement
alone do not complete the full-speed, clean-audio and 5% buffer goal.

### Compilation bursts and renderer-fence measurements

A diagnostic build adds per-frame compilation and wait counters to the corrected
combination. It uses fresh four-open-demo PGO; all four game and four demo
video/PCM sequences match the non-instrumented control. Timings below are
diagnostic attribution, not a candidate speed comparison. After 30 warm-up frames:

| State | Mean JIT CPU time | Mean 2D fence wait | Mean 3D line wait |
| --- | ---: | ---: | ---: |
| Cliff | 0.122 ms | 0.796 ms | 0.043 ms |
| River | 0.128 ms | 1.013 ms | 0.045 ms |
| Menu | 0.008 ms | 1.167 ms | 0.035 ms |
| Ocean | 0.099 ms | 1.506 ms | 0.200 ms |

These costs overlap: compilation contains code emission, and 2D fences can
overlap 3D line waits. They must not be added as exclusive frame costs.
The large reproducible spikes compile many previously unseen blocks:

- Cliff frame 44 compiles **242 blocks**, taking **8.834 ms of thread CPU time**;
  code emission accounts for 5.303 ms of that. The complete core call uses
  23.991 ms of CPU time.
- River frame 100 compiles **244 blocks**, using 9.122 ms of CPU time.
- Ocean frame 36 compiles **249 blocks**, using **9.361 ms of CPU time**,
  including 5.562 ms in code emission. The complete call uses 23.909 ms of CPU.
- Ocean frame 115 compiles no blocks but waits **8.139 ms at a 2D fence**.
  Cliff frame 149 also has no compilation, so JIT work does not explain every
  long frame.

Giving only the 2D worker nice -10 does not consistently solve the problem.
Two reversed-order ocean runs reduce the CPU/handoff service estimate's p95
from 19.69/19.72 ms to 18.90/19.50 ms; emulation off-CPU time changes little.
Reserving CPU 0 for emulation, with other owned player threads on CPUs 1–3,
gives ocean p95 18.12/18.73 ms against its paired control's 19.74/19.74 ms.
Cliff results vary. Neither policy meets the whole goal or persists after tests.
The next fence diagnostic separates work still queued from the delay between
the worker posting completion and emulation resuming.

Diagnostic core SHA256:
`f04653f7ea8d3f6277a4be64ec4d24a17e1e21d70e3de50b49cd96937febebe9`.
Evidence: private `monomelon-frame-cost-20261112/{native-evidence.tar,cost-results.txt}`
and `monomelon-present-20261112/{priority-2d-evidence.tar,priority-2d-results.txt,affinity-combined-evidence.tar,affinity-combined-results.txt}`.

### r6 public source and package checkpoint

The validated CPU changes are now in engine master
[`a99475c0`](https://github.com/monofuel/melonDS/commit/a99475c08eb8f298dc9c0c10e31aba123633bafe),
with wrapper master
[`26975f1e`](https://github.com/monofuel/melonds-ds/commit/26975f1ee151bae485ec7c64bc58d88872a7580b)
pinning that engine. The standalone CMake regression project passes scheduler,
snapshot and 120-frame renderer tests on x86-64, plus actual emitted-dispatch
tests on ARM64 under QEMU. The earlier corrected candidate also passes its
three focused units natively. No diagnostic counters enter these sources.

The new `1.4.0-r6` ebuild changes only source pins. A fresh build from public
checksummed archives retains compiler flags, other dependencies and open-only PGO;
ten compiled engine source hashes match the published checkout. Final core
SHA256: `7e07d202a8a9e04dd2ac3447aea844f4f5b35e094e2da0a40ffd3d9d4377d92c`.
Native package/ABI/dependency checks pass, all four game and four open-demo
video/PCM sequences match, and all four 60-frame paired-display smokes pass.
This package is not installed yet. Fresh package performance comparisons,
deployment, frontend promotion and full goal acceptance remain separate work.
Evidence is in private `monomelon-package-r6-20261112`.

## Earlier measurements

On the Anbernic RG DS Plus, monoMelon `1.4.0-r4` reaches
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

# monoMelon tweaks and performance

**Benchmark update, November 12:** slot 2 is now the river near the start and
slot 4 is a new ocean scene. Slot 1 remains the cliff and slot 3 the menu.
Monofuel reports cliff/menu feel full speed, with slowdowns around water.
The percentage tables below precede this update unless explicitly marked;
old slot-2 measurements are not river measurements. Fresh measurements follow.

## Current four-state measurements

**November 13, installed r11:** core
`e1fa23cd2a0f080a2f84c102f0687f9ece8415937c1cae8899e2a9ec5d045b6c`.
The public pinned package passes eleven native fixtures, five saved-scene and
four FOSS video/PCM comparisons, installed-package checks, four migrated-state
launches and an r9 rollback launch. Original r9 saves remain unchanged; the
normal launcher uses a separate r11 copy. Manual gameplay and physical audio
acceptance remain pending.

Two reversed 720-frame normal/added-delay runs per state, excluding 120 warm-up
frames, have **zero warmed underruns and overruns in cliff, river, inventory and
ocean in all sixteen standard-scene runs**. The probe spins for 1/21 native frame
period in each pipeline stage while preserving video/audio work. It uses a wall
clock, so preemption can reduce the actual CPU time consumed.
Finite-window paced speed is near native; this is a bounded silent stress test,
not an uncapped 105% processing measurement or physical audio verification.
Startup events remain in some logs. The extra heavy fixture has one warmed
underrun/overrun in its first ordinary run; its other ordinary and both taxed
runs have zero warmed events.

The fresh package's separate reversed core comparisons give:

| Scene | r9 core ms | r11 core ms | Throughput gain |
| --- | ---: | ---: | ---: |
| Ocean | 13.603416 | 13.274534 | 2.48% |
| Heavy river | 15.223104 | 14.812467 | 2.77% |

V3 modeled ocean means improve 15.1716/15.3199→14.6624/14.8150 ms; heavy means
16.1483/16.1462→15.6795/15.7634 ms. Tails remain, and that model alone is not
headroom proof. The underlying compiler flags, dependencies and four FOSS PGO
inputs are unchanged. Evidence: `monomelon-package-r11-20261113/`, including
`native-results.txt`, `work-results.txt`, `headroom-results.txt` and deployment
logs. The default player remains `7b977dee…`; headroom instrumentation is unshipped.

### Moving-input r11 replay

The stationary tests above are supplemented by a previously verified 4,910-frame
river recording. Its checkpoint is accepted/re-exported through the original r6
core and r11 into private copies; inputs, options and references stay unchanged.
R11 matches **all 17 original reference images** across the complete recording.
Original recordings/saves remain untouched and normal replay identity checks apply.

Separate actual-player/V3 runs report total underruns/overruns of **5/1** and
**1/0**. These include startup and do not verify physical audio. V3 reconstructs
4,789 warmed periods with zero residual; modeled mean/p95/p99/max work is
12.8172/16.2572/17.8689/28.7467 ms. Some long frames contain substantial owner-thread
CPU work, but its source has not yet been isolated.

Two reversed control/added-delay runs replay the same inputs with null audio,
microphone/captures off and 120 warm-up frames:

| Probe | Warmed frames | Warmed underruns, repeat 1 / 2 | Warmed overruns, repeat 1 / 2 |
| --- | ---: | ---: | ---: |
| Control | 4,790 | 1 / 1 | 0 / 0 |
| Wall-clock spin of 1/21 frame period per stage | 4,790 | 6 / 1 | 2 / 0 |

**The moving sequence still has buffer events.** Neither its mean work estimate
nor the clean stationary runs establishes the full gameplay/headroom goal.
Evidence: `monomelon-r11-river-replay-20261113/`, with separate correctness,
production, V3 and moving-reserve logs. No new core is installed by these tests.

### R11 follow-ups: FIFO values and NEON fog

Two private CPU scouts retain r11's compiler settings and four open PGO demos.
Passing the private eight-byte geometry FIFO entry by value removes addressable
temporaries and stack guards in its callers without changing hardening flags.
The separate fog scout uses exact AArch64 NEON full-colour blending; alpha-only
fog, density calculation and rendering order remain unchanged.

Both scouts and a fresh unchanged control pass all native fixtures (11/11/13),
five saved scenes, four open-demo output comparisons and all **4,910 video/PCM
fingerprints** in the moving river replay. Timing is separate from hashing:
two reversed 600-frame runs per scene after 90 warm-up frames.

| Scene | Installed r11 ms | Fresh control ms | FIFO value ms | NEON fog ms |
| --- | ---: | ---: | ---: | ---: |
| Ocean | 13.513716 | 13.321531 | 13.447585 | 13.517819 |
| Heavy river | 14.902818 | 14.934817 | 14.574580 | 14.738379 |

FIFO gains **2.25% / 2.47%** heavy-river throughput against installed/fresh r11;
ocean is **+0.49% / −0.94%**. It remains a whole-player candidate, not an installed
improvement. Fog gains **1.12% / 1.33%** heavy throughput but loses **1.45%** ocean
throughput against the fresh control; it is set aside. Neither is promoted.

Evidence: `monomelon-r11-cpu-scouts-20261113/`, strict `core-results.txt` and
native archive `b8c6e2de…`. Installed core `e1fa23cd…`, fresh control `0a110c76…`,
FIFO `e6cd6b12…`, fog `14d0c235…`; original saves and installed binaries verify
unchanged, and the menu is restored after testing.

### R11 follow-ups: texture results and JIT coverage

A private packed-texture-result experiment starts at engine `a14c1f0c…`, with
the same wrapper, compiler settings and four open PGO workloads. It returns
colour/alpha in one `u32` instead of two output pointers, preserving texture
reads and arithmetic. The existing format-zero caller bypass remains; a direct
format-zero helper call returns defined zero. No cache or forced inlining is added.
Core: `2678c439670a7700ccdf383194ecc92629ff0ead10281f27bcda9f84cecce61f`.

All twelve ARM64/QEMU and native fixtures, five game and four FOSS video/PCM
comparisons pass. The original-pointer oracle also checks nearly 70 million
lookups. Generated scanline code shrinks 27,156→25,432 bytes; output stores
disappear, while other caller spills remain and unpacking adds mask/shift work.
Smaller code alone does not establish a speedup.

Two reversed 600-frame core comparisons after 90 warm-up frames give:

| Scene | Installed r11 ms | Packed result ms | Throughput change |
| --- | ---: | ---: | ---: |
| Ocean | 13.277226 | 13.115531 | +1.23% |
| Heavy river | 14.613182 | 14.704911 | −0.62% |

A fresh unchanged r11 control (`20f264b7…`, full source manifest verified) has
a different generated-code layout. Against it, packed-result means improve
1.00% ocean / 0.74% heavy, but individual gains range 0.25–1.77% and
−0.04–1.53% respectively. The separate V3 heavy-river modeled means worsen
15.5644/15.3903→15.6278/15.5349 ms against installed r11. These small, variable
results do not establish a consistent improvement over the installed build.
**Not promoted.** Evidence: `monomelon-r11-packed-texel-20261113/`, including
`native-results.txt`, `control-results.txt` and the separate work summaries.

Fresh installed-r11 10-second user-cycle profiles place 46.9% river / 59.2%
ocean of weighted samples in the three software-3D threads. Their scanline and
texture-lookup leaves dominate that work. The emulation owner accounts for
36.8% / 28.2%; JIT-map leaves are about 30.5% / 33.7% of that owner's samples.
DWARF stacks are supplemented with leaf-only exports so JIT samples without
call stacks are retained. These are CPU sample weights, not frame-critical wall time; profiled
playback is not used as speed or clean-audio evidence.

A separate observational diagnostic measures a narrow terminal-self JIT
contract: ARM9/DS/main-RAM code, compiled whole body, final conditional branch
to its exact start, matching live 64-bit publication, current mapping checks and
an enabled conservative mutation epoch. Twelve QEMU/native fixtures and all nine
game/FOSS output comparisons pass. In bounded 720-frame **lifetime** captures,
strict eligible chains are 25.72% cliff, 20.22% river, 15.43% inventory,
24.29% ocean and 24.98% heavy river of actual ARM9 chains. Counts include setup
and load; they describe opportunity size, not a measured speedup. The diagnostic
implements no fast tail. Any candidate must preserve stop/IRQ handling, fresh cycle and
deadline accounting, code validity and mapping checks. Evidence:
`monomelon-r11-self-admission-20261113/` and its corrected v2 fixture.

A guarded self-tail prototype (`df1760a5…`) implements that narrow contract,
retaining register spills, original unsigned bounds/current lookup pointer,
full publication identity, mode and per-iteration timing/stop checks. Its eleven
QEMU/native fixtures and all five game/four FOSS output comparisons pass.
Two reversed core comparisons give:

| Scene | Installed r11 ms | Rebuilt r11 control ms | Self-tail ms | Change vs installed / rebuilt |
| --- | ---: | ---: | ---: | ---: |
| Ocean | 13.342029 | 13.260318 | 13.406827 | −0.48% / −1.09% |
| Heavy river | 14.663753 | 14.732813 | 14.772110 | −0.73% / −0.27% |

Player work means do not supply a compensating win. **Rejected; not installed.**
The runtime measurements do not justify the extra path. Evidence:
`monomelon-r11-self-tail-20261113/`.

A separate passive audio-event diagnostic (`b7551c96…`) records counter changes
after the existing pump/submit calls, without hot-path logging or new audio work.
Two complete 4,910-frame runs have matching event/footer/cumulative counts. One
warmed underrun is observed at submission of frame 403, following owner-thread
CPU times 22.71/18.15/25.82/17.76 ms in frames 400–403; the other run's sole event
is at startup frame 43. These are observation points, not exact device fault times.
The CPU-heavy cluster motivates the engine attribution below. Evidence:
`monomelon-r11-audio-event-trace-20261113/`.

#### Moving-frame compilation attribution

Private diagnostic core `d2500410…` adds bounded, default-off frame/compilation
timers to a14, retaining the r11 recipe and four open PGO workloads. All eleven
native fixtures, five game/four FOSS video/PCM checks and all 17 unchanged replay
references pass. Both instrumented runs contain exactly 4,910 complete engine
records, each inside its corresponding V3 worker interval; accounting and audio
footers validate. No installed package changes.

Selected completed frames from the first instrumented replay, in milliseconds:

| Frame | Owner CPU | Outer compilation path | Backend, within outer | RunFrame CPU outside outer |
| --- | ---: | ---: | ---: | ---: |
| 400 | 24.993 | 7.683 | 4.798 | 16.794 |
| 402 | 27.928 | 6.346 | 4.117 | 21.074 |
| 2880 | 30.689 | 9.700 | 5.994 | 20.405 |

Outer time includes the block's first interpreted execution, so it is **not all
compiler overhead**. Backend time is nested, not an additional cost. The second
run repeats this pattern: frame 2880 has 30.355 ms owner CPU, 9.608 ms outer and
20.262 ms RunFrame CPU outside it. Optimizing compilation alone cannot remove
all the measured long-frame work.

After 120 warm-up frames, each run records 4,896 ARM9 and 228 ARM7 emissions,
with **zero resets, invalidations, retirements, restores or live reattachments**.
Mean outer cost is only 0.0624–0.0628 ms/frame; its occasional bursts matter more
than its average. There are also 14–16 above-native owner-CPU frames with no
compile attempts at all. Profiling the remaining owner work is the next target.

Same-binary OFF/ON/ON/OFF controls have overlapping mean CPU/work results, but
instrumented peaks are larger; do not subtract a guessed timer cost. Both ON runs
have only startup audio events, while the first OFF run observes a warmed
underrun at frame 403. This does not establish that an ON-run burst caused that
separate event, or that instrumentation improves audio. Evidence:
`monomelon-r11-compile-frames-20261113/`, strict joined CSVs and separate audio
contexts; native archive `a6ca9dce…`.

A separate installed-r11 profile uses explicit monotonic sample timestamps to
select the same recorded transition. Of 230 owner samples in frames 392–403,
19 are in inline `RenderRecord` (8.1% cycle-weighted share), versus none of 657
in frames 350–391. These are sampling shares, not exclusive timing or projected
savings. The source forces both 2D engines inline for engine-A capture, raw/FIFO
display modes or excess VRAM dirty waits. Capture can also return without work
for height/mapping reasons. Per-frame reason counters are the next measurement;
the profile alone cannot choose which guard to change. Evidence:
`monomelon-r11-moving-owner-profile-20261113/`, archive `b6aadd36…`.

Before changing that policy, a separate accuracy probe fingerprints every video
frame and PCM block in the 4,910-frame recording. Two installed-r11 runs match
all rows, including 5,372,134 captured `int16` samples; CSV SHA256 `52327f42…`.
This provides a repeatable baseline for short transition errors between the 17
original screenshot references. Hashing runs are separate from timing tests.
Evidence: `monomelon-replay-oracle-20261113/`, final archive `e92270fa…`.

#### 2D fallback reason counts

Diagnostic `db878b59…` keeps rendering policy unchanged and records only four
frame clocks plus counters. All eleven native fixtures, nine game/FOSS output
checks, 17 references and **all 4,910 video/PCM rows** match installed r11.
Both instrumented player runs pass strict 4,910-frame interval/stat accounting.

After 120 warm-up frames, both runs report identical relevant counts:

| Observation | Count |
| --- | ---: |
| Frames with inline scanlines | 25 of 4,790 |
| Inline scanlines | 2,903 |
| Queued scanlines | 916,777 |
| Inline lines caused solely by the dirty-wait threshold | 2,903 |
| Capture/display-mode/no-worker fallback lines | 0 |
| Actual capture calls, including early returns | 0 |
| Open records consumed by OBJ-cache synchronization | 172 in 59 frames |

The fifth dirty wait latches the rest of that frame onto the emulation thread.
Completed frames 400/402/403 draw 70/115/147 of their 192 lines inline, each
after five OBJ-cache waits. Frame 2880 draws 143 lines inline after five BG-cache
waits. Capture is therefore **not the target for this recording**. These counts
do not measure exclusive 2D CPU or promise a particular saving.

Same-binary OFF/ON controls show measurable observer cost and variable audio
events; instrumentation is not an optimization. The next private experiment tests
higher dirty-wait limits while preserving every memory-coherence drain. No limit
change is installed yet. Evidence: `monomelon-r11-2d-reasons-20261113/`, final
archive `96b836ad…`, strict CSVs and separate audio/work summaries.

#### Higher dirty-wait limit: initial scout

Private core `b3669c72…` exposes a fixed per-renderer test limit; the default
remains four. No counters/timers are added, and all original coherence drains
and live-memory guards remain. Limits 4/8/16/32/192 each pass five saved-scene
and four FOSS output comparisons plus **all 4,910 video/PCM fingerprints**.
All eleven native fixtures pass. This test interface is not intended to ship.

Two reversed 900-frame player passes show consistent transition CPU reductions
at limit 32, compared with four in the **same binary**:

| Completed frame | Limit 4 owner CPU, repeat 1 / 2 | Limit 32 owner CPU, repeat 1 / 2 |
| --- | ---: | ---: |
| 398 | 25.804 / 25.548 ms | 23.431 / 23.293 ms |
| 402 | 26.484 / 26.895 ms | 24.477 / 24.337 ms |
| 403 | 18.268 / 18.420 ms | 15.428 / 15.118 ms |

Frame 402's full core-service time also falls 1.27/2.43 ms. These are transition
savings, **not a general game-FPS improvement**. Modeled mean work stays nearly
flat: four gives 11.272/11.340 ms versus 32 at 11.300/11.241 ms; p99 and audio
remain mixed. Limits 32 and 192 are close on the selected CPU tails. The scout
does not record their actual fence counts.

Limit 32 is selected for the next confirmation, not promotion: full 4,910-frame
4/32/32/4 comparisons with both the timing and normal players, including the
unseen BG-heavy frame 2880. Four-state margin and manual acceptance remain
required. Frequency samples are all 1.992 GHz, temperatures 51.9–53.8°C, with no
policy changes. Evidence: `monomelon-r11-dirty-limit-20261113/`, scout final
archive `ee1f643b…`; installed r11 remains unchanged.

The full-route confirmation repeats the tail reduction in both reversed V3
runs. At the previously unseen BG-heavy frame 2880, owner CPU falls
**28.042/28.267→24.548/24.368 ms**, and core service falls
**28.820/29.252→26.004/25.876 ms**. Maximum modeled work falls
29.012/29.351→26.526/26.112 ms. Mean work remains nearly flat
(four:12.974/13.026 ms; 32:12.966/12.982 ms), with mixed p99 results.

Warmed V3 underruns/overruns are four **0/0 and 4/1**, versus 32 **0/0 and 1/0**.
Normal-player totals, including startup, are four **2/0 and 3/1**, versus 32
**2/2 and 0/0**. These small, variable audio results do not establish clean
physical audio or an audio fix. All guards/restoration checks pass. Evidence:
`extended-final-evidence.tar`, SHA256 `531cc634…`, in the same experiment root.

These results motivated a **constant-only** candidate: change the original
budget from four to 32, with no experimental setting or member. Its independent
build and validation results follow; transition savings alone do not establish
the full 100%+5% goal.

#### Constant-only build: shorter spikes, mixed overall results

Fresh core `21679148…` changes only the budget constant from four to 32.
The normal four-FOSS-PGO build passes eleven native fixtures, five saved-scene
and four FOSS comparisons, and **all 4,910 video/PCM fingerprints** against the
installed-r11 oracle. No runtime tuning interface or diagnostic enters the core.

Two reversed full-player comparisons reproduce the shorter transition spikes:

| Completed frame | Installed r11 owner CPU, repeats 1 / 2 | Constant 32 owner CPU, repeats 1 / 2 |
| --- | ---: | ---: |
| 398 | 24.910 / 25.078 ms | 23.437 / 23.328 ms |
| 402 | 25.743 / 26.060 ms | 24.454 / 24.603 ms |
| 403 | 17.789 / 17.633 ms | 15.161 / 15.272 ms |
| 2880 | 27.683 / 27.568 ms | 24.529 / 24.731 ms |

Maximum modeled work improves 28.946/28.814→26.234/26.587 ms, but mean work
worsens 12.742/12.760→13.018/12.965 ms, and p95 rises. This is a measured
tradeoff, not a broad throughput win. Separate reversed headless means also
show no general gain: ocean installed/fresh-control/candidate
13.2525/13.1941/13.2703 ms; heavy river 14.7382/14.5768/14.7936 ms.

Warmed instrumented underruns/overruns are installed **1/1 and 7/1**, versus
candidate **0/0 and 0/0**. Normal-player totals, including startup, are installed
**2/0 and 1/0**, versus candidate **1/0 and 4/1**. Consequently these tests do
not establish an audio fix. All strict 4,910-row, audio-footer, timing
reconstruction and final binary/save/menu checks pass.

Reversed 720-frame reserve checks exclude 120 warm-up frames. All ten
added-workload runs (four required states plus the heavy fixture, twice each)
have zero warmed buffer events. Ordinary runs retain one ocean underrun and
one heavy-fixture overrun in their second repeats. The other ordinary runs
are clean. This preserves the distinction between stationary and moving tests.

The full moving-input reserve check still fails:

| Constant-32 probe | Warmed frames | Warmed underruns, repeats 1 / 2 | Warmed overruns, repeats 1 / 2 |
| --- | ---: | ---: | ---: |
| Control | 4,790 | 2 / 1 | 1 / 0 |
| Extra 1/21 native frame-period CPU work per stage | 4,790 | 14 / 11 | 1 / 1 |

**Not promoted.** Shorter transition spikes do not establish better overall
playback, and this artifact does not meet the moving-input reserve target.
The public source, ebuild pins and installed r11 remain unchanged. All original
and live saves pass final checks; the launcher is restored after every batch.
Twenty stationary start-frequency samples are 1.992 GHz, temperatures
45.6–60.0°C; no clock policy is changed.

Private evidence: `monomelon-r11-dirty-constant-20261113/`, native archive
`1efe8751…`, full-player `b281fb2e…`, stationary reserve `5c937313…`, moving
reserve `9d61ca71…`. All archives include post-cleanup guards. No physical-audio
or manual-gameplay acceptance is inferred from silent tests.

### Earlier r9 measurements

**November 13, installed r9:** fresh 720-frame runs use the unchanged production
player (`7b977dee…`) and separate V3 diagnostic runs, copied saves, null audio
and microphone off. The production runs report three underruns in cliff and zero
in river, inventory and ocean; the heavier moving-river fixture reports one. This does not verify
physical audio or representative manual play.

V3 gives 599 warmed periods per scene after 120 warm-up frames:

| Scene | Modeled work mean / p95 ms | Periods above native budget | Production underruns |
| --- | ---: | ---: | ---: |
| Cliff | 14.9922 / 15.7762 | 6 / 599 | 3 |
| River | 14.5337 / 15.9515 | 18 / 599 | 0 |
| Inventory | 7.5942 / 8.0370 | 0 / 599 | 0 |
| Ocean | 14.9395 / 17.3115 | 39 / 599 | 0 |
| Heavier river | 15.8747 / 17.2754 | 41 / 599 | 1 |

Each mean is below the 15.919 ms target, but individual long periods remain.
The accounting model reconstructs actual intervals with zero residual; it is
not an exact unpaced counterfactual and does not prove the complete 5% margin
or smooth gameplay. Keep the goal open. Diagnostic ocean reports two underruns
where its separate production run reports zero; these are different runs,
not identical scheduling. These V3 runs' paced whole-loop speed averages are
99.355% cliff, 99.437% river, 99.949% inventory and 99.445% ocean, including
startup/final-presentation overhead. The previous zero-underrun cliff summary
was a reading error; the retained raw logs report production 3/V3 1.
Evidence: `monomelon-r9-full-pipeline-20261113/`.

### Geometry and buffer-retention candidates

November 13 comparisons use two reversed 600-frame core runs after 90 warm-up
frames. Each candidate passes native ARM64 fixtures, all five saved-scene
video/PCM comparisons and all four open-training-ROM comparisons. These are
prototype measurements; the selected combination is packaged in r11 above.
Means below describe core processing, not complete player headroom.

| Candidate | Ocean gain vs installed r9 | Heavy river gain vs installed r9 | Limitation |
| --- | ---: | ---: | --- |
| NEON 4×4 matrix multiply, scalar overlap path | −0.08% | +1.17% | Ocean flat; player still has audio-buffer misses. |
| Reuse completed helper interiors during next-frame seeding | +0.64% | +1.07% | Heavy player work/tails mixed; copyback still runs. |
| r10 inline depth + matrix + seed reuse | +1.73% | +1.52% | Occasional production-player misses remain. |
| r10 + lazy helper ownership, removing recurring copyback | +1.83% | +1.79% | Ocean player results improve; heavy misses remain variable. |
| r10 + lazy ownership + NEON matrix + builtin CLZ | +2.48% | +1.94% | No ocean production underruns in either repeat; heavy still has misses. |
| Same combination + cached FIFO DMA eligibility | +3.39% | +3.18% | Heavy work tails improve; ocean audio misses favor the three-part build. |

Fresh unchanged r9 controls accompany all three comparisons. Against those
controls, combined throughput improves 2.45% ocean / 1.86% heavy river.
Rebuild/profile variation affects tiny comparisons; the matrix microbenchmark's
2.05–2.10× routine speedup does not describe whole-game throughput. Evidence:
`monomelon-r9-matrix-audit-20261113/`,
`monomelon-r9-band-seed-reuse-20261113/`,
`monomelon-r10-matrix-seed-20261113/`.

The lazy-copy candidate retains helper ownership until a transition requires
canonical buffers. Independent scalar-oracle, poisoned-boundary, save/load,
nine native fixtures and all output comparisons pass. Against its matching
fresh **r10** control, throughput improves 1.38% ocean / 1.61% heavy river.
Its standalone binary was not deployed: heavy-river production underruns are
1/1 for installed r9 and 1/2 for the candidate. R11 adopts it after combination
testing. Evidence: `monomelon-lazy-band-copy-20261113/`.

Both combined builds pass eleven ARM64/QEMU fixtures each, the same fixtures
natively, all five saved-scene output comparisons and all four FOSS comparisons.
They use fresh open-demo PGO with verified full source manifests and actual
NEON/CLZ instruction checks. In the direct comparison, adding DMA eligibility
gains 0.89% ocean / 1.22% heavy over the three-part build. Production ocean
underruns are 0/0 for three-part and 1/1 for four-part; heavy is 1/1 versus 2/1.
The four-part heavy V3 modeled mean/p95 improves to 15.45/16.28 and 15.56/16.39 ms,
but this remains a work model rather than complete headroom proof. Warmed
normal/tax comparisons select the three-part build: both reversed repeats in all
four standard scenes have zero warmed underruns/overruns, with or without
1/21 frame-period CPU work added to each pipeline stage. The extra heavy fixture
still has taxed underruns 1/0 and overruns 1/1. The four-part build has taxed ocean
underruns 3/0 and heavy 0/3, so its small processing advantage does not justify
the DMA change. These are bounded silent stress tests, not complete gameplay or
uncapped 105% capacity proof. R11 adopts the selected source; its fresh-package
validation and installation are recorded above.
Evidence: `monomelon-cpu-stack-comparison-20261113/`.

Scoped compilation diagnostics count real logical-immediate checks without
changing emitted code. A warmed ocean burst has 113 blocks / 1,788 checks /
5.130 ms backend CPU; heavy river has 239 / 1,173 / 5.784 ms. Two reversed matched
comparisons prove identical event identities, order, emission sizes/offsets and
logical counters. The builtin CLZ reduces those ocean bursts from 5.03/5.12 to
4.24/4.20 ms (16–18%) and heavy bursts from 5.68/5.67 to 5.04/4.96 ms (11–12%).
These instrumented non-PGO results describe compilation CPU, not overall FPS.
Evidence: `monomelon-r9-clz-traffic-fast-20261113/`.
Five individual records in the original diagnostic have zero recorded
CPU duration despite positive wall duration and remain in the accounting.

DMA diagnostics find roughly 4,445 ocean / 6,723 heavy-river geometry-FIFO DMA
checks per warmed frame, with no matching channel enabled in these samples.
The resulting cached eligibility gate passes native lifecycle, enable/disable,
state-load, DSi NDMA and all nine output checks. Two reversed comparisons against
fresh r10 give **−0.52% ocean / +1.25% heavy-river** throughput; production audio
counts do not improve consistently. It remains private. Counting avoidable work
alone does not establish a whole-pipeline gain. The combined stress comparison
also favors the three-part build, so r11 excludes this gate.
Evidence: `monomelon-fifo-dma-gate-20261113/`.
Evidence: `monomelon-r9-clz-traffic-20261113/` and
`monomelon-dma-traffic-20261113/`.

### Earlier r4 baseline

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

The outer JIT path includes decoding, bookkeeping and the block's first
interpreted execution, as well as code emission. Its time is not exclusively
compiler overhead. Renderer waits here concern CPU software rendering, not
Panfrost display presentation.

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

That follow-up diagnostic now completes all four 120-frame output comparisons
and 240-frame player traces. Each fence records when it is queued, when the
worker posts completion and when emulation returns from its wait:

| State | Mean fence wait | Before worker completion | Completion-to-return |
| --- | ---: | ---: | ---: |
| Cliff | 0.804 ms | 0.740 ms | 0.064 ms |
| River | 1.015 ms | 0.927 ms | 0.089 ms |
| Menu | 1.219 ms | 1.073 ms | 0.146 ms |
| Ocean | 1.468 ms | 1.377 ms | 0.092 ms |

The first phase includes queued rendering, worker preemption and waits for 3D
rows; it is not pure compute time. An ocean 6.169 ms fence includes 5.710 ms
of 3D-line waiting, while another 4.202 ms fence includes only 0.044 ms of it.
Thus a wakeup-only change cannot remove most fence latency. The smaller-batch
comparison below tests whether reducing queued work helps.
No new scheduling policy ships. Evidence:
`monomelon-fence-phase-20261112/{native-evidence.tar,cost-results.txt}`; diagnostic
core SHA256 `9089b9d69ec9b76d260a89580fa8236b2e6dca5d56d982fe21fa0ff368ac7489`.

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
Initial package validation precedes the timing and deployment described below.
Frontend promotion and full goal acceptance remain separate work.
Evidence is in private `monomelon-package-r6-20261112`.

After charging, three fresh alternating pairs compare this exact package with
installed r5, using the same private render-ahead trace player for both:

| State | r5 core capacity | r6 core capacity | r5 player speed | r6 player speed |
| --- | ---: | ---: | ---: | ---: |
| Cliff | 103.296% | 108.721% | 97.202% | 98.163% |
| River | 109.199% | 115.077% | 98.152% | 98.255% |
| Menu | 219.892% | 234.642% | 99.725% | 99.678% |
| Ocean | 108.825% | 114.894% | 95.566% | 97.404% |

The package improves core throughput by **5.25–6.71%**. Player measurements
include startup and the final physical flip; they do not measure 5% processing
headroom. Across the three runs, null-backend audio underruns fall from 14 to
zero at the cliff and from 19 to three at the ocean; menu and river stay at
zero. These counters do not replace listening to normal audio. Both variants
use the same experimental frontend, so the table does not establish performance
through the installed launcher's existing presenter. Original/live saves and
installed binary checks pass; the normal launcher returns. Evidence:
`monomelon-package-r6-20261112/{r5-comparison-evidence.tar,r5-comparison-results.txt}`.

R6 is now installed through Portage. All four states are migrated through the
core API into `monomelon-r6-lost-in-blue`; original r5 saves remain intact.
Four installed-player smokes and an r5 rollback-launcher smoke pass, along with
package, binary and original-save checks. Backup SHA256:
`fba3767465711730452e65a3de937c619829e0d98198458d036ff3f2bc31c669`.
Both host and device copies verify. The normal presenter is unchanged; the
private render-ahead player used for comparisons is not installed.

Four additional 600-frame runs use that experimental presenter with r6 and null
audio. Each reports zero underruns/overruns. A preselected 180-frame warm-up
separates sustained behavior from startup; warmed submission intervals average
16.712–16.715 ms. Core/handoff service means are 15.583 / 14.982 / 7.571 /
15.866 ms for cliff/river/menu/ocean, but p95 is 17.068 / 16.615 / 8.069 /
18.880 ms. Ocean still has a 23.156 ms service outlier. This estimate excludes
other foreground dependencies and cannot prove 105% whole-pipeline capacity.
Normal physical audio and representative manual gameplay remain unverified.
Evidence: `monomelon-package-r6-20261112/{deploy-evidence.tar,steady-evidence.tar,steady-180-results.txt}`.

### r9 deferred perspective factors

Engine [`09556fef`](https://github.com/monofuel/melonDS/commit/09556fef981d01d05888b0a55d0a0baddda7a82d)
keeps the interpolation arithmetic and moves its perspective division after
depth acceptance for Z-buffered pixels. W-buffer depth still prepares the factor
first; Y slopes keep the original `SetX` path. Wrapper
[`c705c103`](https://github.com/monofuel/melonds-ds/commit/c705c10385d4797ad8a83f56cdc69e5f202837b8)
pins that engine. R9 changes only source pins; compiler flags and the four open
PGO inputs are unchanged.

Private candidate `3d5ad588…` passes all four native game/four open-demo output
comparisons. Two alternating 360-frame core pairs after 90 warm-up frames give
ocean **14.2217 to 13.6542 ms (+4.156%)**, heavier river **15.0963 to 15.0094 ms
(+0.579%)**. Matching player runs measure 600 steady frames after 120 warm-up
frames, with null audio and microphone disabled: ocean underruns **4 to 0**,
heavy **0/0**. Each candidate heavy run has one overrun. These are not physical
audio acceptance or whole-pipeline margin measurements.

The published focused test compares depth/attribute preparation with the existing
unsplit API across both directions/depth modes, wrapping spans, signed extremes
and consecutive rejections. The full host suite passes. The larger private test
also compares over 675 million values per seed with a fresh r8 reference;
omitting preparation is detected.

The extra texel cache below is not included. A direct three-pair comparison gives
deferred-only versus combined core times of **13.6595/13.7610 ms** for ocean and
**15.0038/15.0422 ms** for heavier river. The last pair reverses direction, and
there is no demonstrated incremental win from the cache. Keep the simpler path.

The fresh public-source r9 package is **installed**, core SHA256
`1e2bdd76fe1df89931ad94fe1c38d3340289a32cf6944e2c1eff71a63a33ec9a`.
All four native game and four open-demo video/PCM comparisons match r8. Four
normal-player smoke tests and an explicit r8 rollback smoke pass. Saves are
migrated into `monomelon-r9-lost-in-blue`; all original/live r8 saves, both
microphone-enabled player binaries and the upstream core remain unchanged.

Post-install checks run 600 frames per scene, with 90 warm-up frames before
core timing. Player measurements include startup, normal pacing and final
presentation, using paired GPU displays, null audio and microphone disabled:

| Scene | Core ms/frame | Core capacity | Player loop ms | Audio underruns / overruns |
| --- | ---: | ---: | ---: | ---: |
| Cliff | 14.1733 | 117.934% | 10,097 | 0 / 0 |
| River | 13.7813 | 121.289% | 10,093 | 0 / 0 |
| Inventory | 6.9743 | 239.668% | 10,030 | 0 / 0 |
| Ocean | 13.5324 | 123.519% | 10,097 | 1 / 1 |
| Heavier river | 14.9731 | 111.634% | 10,152 | 5 / 1 |

These are not warmed-only player results, physical audio acceptance or proof
of 105% whole-pipeline capacity. Original/save/binary integrity checks pass and
the normal launcher is restored. The full goal remains open. Evidence:
`monomelon-package-r9-20261112/{before-r9-backup.tar,deployment-evidence.tar,post-install.log}`.

### R9 profiles and added-work checks

Fresh 900-frame paired-GPU runs profile eight seconds after two seconds of
warm-up, with user-cycle sampling at 397 Hz and per-thread task-clock counters.
No lost samples. Ocean's polygon scanline routine accounts for **39.88%** of
sampled user cycles, texture lookup **10.12%**. These are aggregate sample
shares, not individual functions' elapsed frame costs.

The heavier river remains sensitive to the emulation owner thread: it uses
**7,321 ms of task-clock in 8 seconds**, about 91.5% of one core. Its DSO and
generated JIT code account for **25.60% and 12.67%** of aggregate samples.
The three 3D workers use **4,417 / 2,701 / 1,249 ms**, and 2D uses **2,279 ms**.
Work overlaps; adding these times does not give frame latency. The profile does
not establish memory-bandwidth saturation or that all four cores are busy.

Two alternating private added-work/control pairs measure 600 steady frames
after 120 warm-up frames. The probe adds about 0.796 ms to each of the core and
frontend stages; the control has identical counters without that delay. Both
use the installed r9 core, neutral input, null audio and no microphone:

| Scene | Control underruns | Added-work underruns | Control overruns | Added-work overruns |
| --- | ---: | ---: | ---: | ---: |
| Cliff | 0 | 9 | 0 | 1 |
| River | 0 | 0 | 0 | 0 |
| Inventory | 0 | 0 | 0 | 0 |
| Ocean | 2 | 11 | 0 | 0 |
| Heavier river | 7 | 6 | 0 | 1 |

These are totals across both repeats. The heavy scene varies enough that the
added-work total is lower; that does not make the added work an optimization.
This indirect stress test exposes fragile playback, but neither passes nor
failures establish an exact whole-pipeline capacity percentage. The full goal
remains open. Both diagnostic players are private; the normal microphone-enabled
player stays unchanged. Evidence: `monomelon-r9-profile-20261112/{native-evidence.tar,stress-evidence.tar,stress-results.txt}`.

### R9 pipeline timing: core service tails

A private diagnostic player records command issue/receipt, core reply readiness,
main-thread collection, next submission and paired-display completion timing.
It keeps the existing microphone-enabled source/dependency pins and changes no
emulation or display policy. Automated runs use null audio and microphone off.
The normal installed player is not replaced.

DRM's monotonic timestamp capability is checked before using event timestamps.
Only the part of a display poll before its completion timestamp is classified
as a refresh wait; callback work and wakeup delay remain. Software pacing removes
requested sleep duration, retaining oversleep and event processing. Receipt-time
pacing counters handle frames collected early by autosave. There is no per-frame
logging until playback stops and no shared hot-stage timing array.

The overlapping-period model uses the larger of core service and frontend work
before collection, plus the remaining handoff work. Actual intervals reconstruct
with **zero nanoseconds discrepancy** across each measured sequence; synthetic
cases exercise both barriers and autosave collection. This validates accounting
alignment, not an exact prediction of a faster unpaced run: changing scheduling
can change contention. Do not treat the model as completion proof.

The latest diagnostic measures 599 periods after 120 warm-up frames:

| Scene | Modeled work mean / p95 ms | Core-owner CPU mean ms | Core non-CPU mean / p99 ms | Modeled periods above native budget |
| --- | ---: | ---: | ---: | ---: |
| Cliff | 14.9046 / 16.2432 | 13.6594 | 1.1077 / 3.1129 | 10 / 599 |
| River | 14.6452 / 16.5614 | 12.9471 | 1.5120 / 4.0644 | 25 / 599 |
| Inventory | 7.6324 / 8.1426 | 6.0462 | 1.2387 / 1.8228 | 0 / 599 |
| Ocean | 15.1787 / 18.2632 | 12.6402 | 2.0646 / 6.5073 | 73 / 599 |
| Heavier river | 15.8756 / 16.9269 | 14.5216 | 1.1563 / 3.2063 | 48 / 599 |

Core non-CPU time is execution wall time minus that owner's thread CPU time;
it includes renderer waits and descheduling, which this trace cannot distinguish.
Command queue delay is measured separately. Frontend work includes GPU completion
and polling overhead after classified waits; it is not CPU-only time.

Ocean frame 444 spends **12.747 ms on the owner CPU but 13.619 ms off-CPU**;
frame 467 also has a **4.317 ms command-queue delay**. By contrast, heavier-river
frame 333 spends **22.755 ms on the owner CPU**, with only **1.491 ms off-CPU**.
Investigate renderer/fence and scheduling delays separately from CPU/JIT bursts;
another small average pixel-loop gain alone does not explain these tails.
Neither physical-audio acceptance nor the full goal is established.
Evidence: `monomelon-worktrace-20261112/{trace-cpu.tar,native-evidence-v3.tar,results-v3.txt,analyze.nim}`.

### Refreshed r9 JIT and fence attribution

Diagnostic core `511d3ab7…` rebases the older compilation/fence probes onto r9.
It buffers samples until console destruction, uses owner-local counters and
keeps scanline counters on a separate cache line. Six host fixtures, native
four-state/heavier-river comparisons and all four open-demo comparisons pass.
This instrumented core is not installed and its timings are attribution, not
candidate speed claims.

Initial combined stdout/stderr captures contain interleaved, malformed timing
fields. They are retained but excluded from analysis. Only the five player runs
are repeated with separate streams; all 720 engine rows match the corresponding
worker timestamp interval in each clean run. The following means cover 599
periods after 120 warm-up frames:

| Scene | Outer JIT CPU ms | 2D fence ms | 3D scanline-wait delta ms |
| --- | ---: | ---: | ---: |
| Cliff | 0.0065 | 0.8108 | 0.0407 |
| River | 0.0363 | 0.9571 | 0.0406 |
| Inventory | 0.0022 | 1.1526 | 0.0346 |
| Ocean | 0.0321 | 1.3022 | 0.1312 |
| Heavier river | 0.0354 | 0.7734 | 0.0412 |

The outer JIT cost includes decoding and the block's first interpreted execution,
not just code emission. Fence and scanline waits overlap; do not add them.
Cross-thread line totals describe the frame interval rather than an exact causal
assignment of every asynchronous line.

- Heavier-river frame 333 compiles **239 blocks**, using **7.960 ms of owner CPU**
  inside that path. Ocean frame 620 compiles **113 blocks**, using **6.474 ms**.
- Ocean frame 476 waits **4.882 ms** at a 2D fence, with a **2.869 ms** scanline-wait
  delta. Frame 462 has **4.787 ms** fence wait and **3.930 ms** line-wait delta.
  Fence post-to-return delay is only about **0.08 ms on average** in ocean;
  much of the delay precedes completion notification.
- Cliff frames 149 and 449 use **18.066 / 17.138 ms of engine CPU**, with no JIT
  compilation or fence wait. Heavier-river frame 486 likewise uses **18.975 ms**
  with neither cost. These require a separate active-execution profile.

The same three categories existed in earlier diagnostics; the fresh capture
confirms they remain relevant after r9. Evidence:
`monomelon-r9-core-phase-20261112/{build-evidence.tar,clean-evidence.tar,results-clean.txt,analyze.nim}`.

### Existing JIT options: retain defaults

The installed r9 binary is also tested with literal optimization disabled,
branch optimization disabled, and both disabled. Each uses private overrides
and copied saves; normal launchers/defaults stay unchanged.

Disabling branches, alone or with literals, changes captured video/PCM output
in all five tested scenes. This is an output difference, not a determination
of which mode is more accurate to hardware. Reject these variants under the
preserve-output requirement without timing them. Disabling only literals matches
all five 120-frame sequences, but two reversed 600-frame timing pairs after
90 warm-up frames are slower:

| Scene | Default / literals-off core ms | Throughput change |
| --- | ---: | ---: |
| Ocean | 13.6140 / 13.8246 | −1.523% |
| Heavier river | 15.0408 / 15.3961 | −2.308% |

No option change ships, and no additional full-player tests of these losing
variants are needed. Evidence:
`monomelon-r9-core-phase-20261112/{jit_options_device.sh,jit-options.log,jit-options-evidence.tar}`.

### Quotient reuse: private candidate, not selected

Candidate `ed39fe00…` starts from r9 and tests the preceding perspective quotient
against the new numerator/denominator. A bounded 64-bit residual accepts an exact
same/adjacent quotient; all other cases retain unsigned division. Y interpolation
is unchanged. There is no floating-point approximation or rendering shortcut.

The six host fixtures pass. Independent scalar-reference tests compare
**675,013,042 and 677,352,128 values**, with zero mismatches, including wrapping
and rejected-pixel sequences; an omitted-preparation mutant fails. The first
seed also passes as ARM64 code under QEMU. All four native game and four open-demo
video/PCM comparisons match r9, as does the heavier river sequence.

Fresh four-open-demo PGO, two alternating 360-frame core pairs after 90 warm-up
frames, and matching 600-frame steady player windows give:

| Scene | R9/candidate core ms | Core throughput change | R9/candidate player speed | Steady underruns |
| --- | ---: | ---: | ---: | ---: |
| Ocean | 13.7856 / 13.9202 | −0.967% | 100.066 / 100.076% | 1 / 1 |
| Heavier river | 15.2396 / 15.0618 | +1.181% | 100.173 / 100.176% | 0 / 0 |

The small mixed result does not justify shipping the extra arithmetic and
branches. Keep r9 installed. All save/binary checks pass and the launcher is
restored after the comparison. Evidence:
`monomelon-r9-factor-reuse-20261112/{build-evidence.tar,native-evidence.tar,results.txt,unit.log,unit-seed2.log,arm64-unit.log}`.

### Register-use plans: private candidates, not selected

R9's register allocator rescans the remaining instruction masks for each compiled
instruction. Two candidates precompute identical suffix masks and eviction ranks:
one owns a vector in the cache; the other borrows a block-local plan and preserves
the cache's original size and alignment. Neither changes the emitted allocation
decisions in 1,902,748 differential preparation steps and 6,623,343 load/store
actions. Host regressions, ARM64 QEMU and native video/PCM comparisons pass.

Two reversed pairs of 600 core frames after 90 warm-up frames give these mean
times; each row has its own contemporaneous r9 control:

| Candidate | Ocean r9/candidate ms | Heavier river r9/candidate ms |
| --- | ---: | ---: |
| Vector in cache (`9e4de32f…`) | 13.6671 / 13.5487 | 15.0215 / 15.0401 |
| Borrowed plan (`98a939d9…`) | 13.5736 / 13.6196 | 14.8981 / 15.0493 |

The small ocean gain in the first variant does not carry over to heavier river
or consistently improve player tails. The borrowed version is slower in both
core workloads. Neither ships. The corresponding 720-frame player runs still
have modeled work periods above the target; their timing does not establish
the required headroom. Evidence:
`monomelon-r9-register-plan{,-view}-20261112/{native-evidence.tar,results-*.txt}`.

### Smaller JIT candidates: private, not selected

Two further r9 candidates preserve video/PCM for the four current states,
heavier river and four open demos. Both use fresh four-open-demo PGO and two
reversed 600-frame core comparisons, with separate 720-frame player runs:

| Candidate | Ocean r9/candidate ms | Heavier river r9/candidate ms |
| --- | ---: | ---: |
| ARM64 paired exit/flush stores (`ee4f2133…`) | 13.5907 / 13.6948 | 15.0314 / 15.1665 |
| Compute eviction ranks only under pressure (`75882e57…`) | 13.5719 / 13.7345 | 15.0045 / 15.2527 |

Paired stores pass 524,288 generated ARM64 executions under QEMU and natively,
checking CPU bytes, guards, flags and cache metadata; dispatch tests also pass.
Lazy ranking preserves cache layout and matches 5,708,244 preparations and
19,919,229 allocation actions at the real 15/7/8-register capacities. All six
host fixtures pass for both, and deliberate test mutants are rejected.

Neither candidate produces a repeatable timing benefit. Player work tails remain
above the target, so both are left uninstalled. Smaller emitted code or less
source-level bookkeeping alone is insufficient evidence of a performance win.
Evidence: `monomelon-r9-{paired-spills,lazy-ranking}-20261112/`, including
`build-evidence.tar`, `native-evidence.tar` and `results-*.txt`.

### Local dispatch jump sites: private, not selected

R9 already chains compiled blocks through a shared lookup tail. Candidate
`1f0f03b8…` tests local final jump sites: each block calls the shared lookup,
then jumps to its returned target. The lookup retains the cycle/deadline,
stop, region and fresh-entry tag checks. This adds four bytes per exit and one
executed instruction per successful transition; it does not cache target pointers.

All seven generated/native ARM64 fixtures pass, including alternating targets,
ARM/Thumb transitions, helpers and conditional exits. Video/PCM matches r9 for
the four current states, heavier river and four open demos. Two reversed
600-frame core pairs give:

| Scene | R9 / candidate ms | Candidate throughput change |
| --- | ---: | ---: |
| Ocean | 13.5766 / 13.8828 | −2.21% |
| Heavier river | 15.0343 / 15.2286 | −1.28% |

Separate 720-frame player comparisons show no consistent work-tail improvement.
Fewer null-backend underruns do not establish clean physical audio or outweigh
the slower measured work. R9 stays installed.

A subsequent eight-second per-thread PMU comparison uses the production player
after two seconds of warm-up, with no concurrent transfer and all counters
running throughout. Emulation-thread branch misses increase from
11.190 to 11.715 MPKI in ocean and 11.829 to 12.153 in heavier river. Instruction
refills decrease slightly, but IPC falls from 0.507 to 0.503 and 0.531 to 0.524.
This candidate does not deliver the proposed branch-prediction benefit on this
workload. Counters diagnose this experiment; they do not isolate a unique cause
of all remaining slow frames.

Evidence: `monomelon-r9-local-dispatch-20261112/{native-evidence.tar,results-*.txt}`
and `pmu-evidence.tar`, with its analyzer/output under `pmu/`.

### Texture blocks and resident registers: private, not selected

Two r9-based candidates use fresh four-open-demo PGO and two reversed
600-frame core comparisons, with separate 720-frame player traces:

| Candidate | Ocean r9 / candidate ms | Heavier river r9 / candidate ms |
| --- | ---: | ---: |
| Scanline-local compressed texture block (`bf7a45f1…`) | 13.6292 / 13.7469 | 14.9878 / 15.3117 |
| ARM64 resident R0/R1 pair (`a8cf8613…`) | 13.5719 / 13.8291 | 14.9923 / 15.4783 |

The texture candidate keeps one aligned 4×4 packed block, palette metadata and
four lazily decoded colors in a 24-byte scanline-local cache. No renderer fields
or persistent invalidation state change. All eight ARM64/QEMU/native fixtures,
roughly 18 million actual-sampler versus independent-r9 comparisons, and seven
negative mutants pass their respective positive/negative expectations. A new
independent full-frame harness adds textured polygons: all 826 complete renderer
fingerprints match r9 under QEMU and natively. The older frame harness did not
texture its polygons and would not cover this integration by itself.

The resident-register candidate carries guest R0/R1 in native W19/W20 between
blocks, synchronizing at dispatch/return, interpreter, helper and patched memory
boundaries. Eight ARM64 fixtures pass under QEMU and natively; its new generated
test covers unused middle blocks, conditional fallbacks, bank changes, literals,
helpers and patched slow-memory trampolines. The fixture calls patched paths
directly; it does not itself trigger signal recovery. Real game comparisons
retain normal fast memory. Default allocator behavior also matches r9 across
5,708,244 preparations, and a resident semantic model checks 100,000 chains.

Both preserve video/PCM for all four states, heavier river and four open demos.
Both are slower in both core scenes, with no consistent player-tail win: texture
throughput changes −0.86%/−2.12%, resident pair −1.86%/−3.14%. Neither ships.
Evidence: `monomelon-r9-{texture-block,resident-pair}-20261113/`, including
build/native evidence archives and paired worktrace summaries.

### Scheduling and JIT restoration follow-ups: private, not selected

Source-validated startup ordering and a DWARF profile identify the emulation
owner, primary 3D worker, two 3D helpers and 2D worker. Pinning the owner to CPU0,
main/2D to CPU1 and 3D to CPUs2–3 makes ocean modeled mean work approximately
17.88–17.92 ms versus 14.93–15.05 ms with default scheduling. Ocean underruns
increase from 8/6 in the two controls to 47/49. A second layout preserves three
3D cores, giving each worker a separate core and sharing the foreground/2D work
with the shortest 3D band. Its two ocean runs have 6/14 underruns versus 6/7 in
the controls. Neither temporary policy ships. Default runs also vary; an earlier
zero-underrun ocean sample is not proof of consistent clean playback.

A separate diagnostic expands the restore-cache key to include address and CPU
alongside the instruction hash, retaining existing literal/range validation.
Generated fixtures reproduce the old cache's candidate collisions and verify
the proposed key, but the actual saved scenes never use this path: both key
modes produce exactly 2,085 new blocks in ocean and 2,053 in heavier river, with
zero retirements, restores, replacements or repeated compiled identities. All
observed blocks are first-use compilation. This key change cannot remove those
bursts and is not shipped as a performance improvement.

The diagnostic measures actual backend compilation CPU separately from outer
lookup/decode work. Warm heavier river has a 239-block burst costing 5.467 ms of
backend CPU; ocean has a 113-block burst costing 5.110 ms. Most total compilation
is startup. These are attribution measurements, not wholly recoverable time.
The initial open-demo trace exceeds its explicit 65,536-event recorder capacity
and aborts; that run is invalid. A preserved-failure continuation disables only
the recorder for the open-demo accuracy checks. All eight native fixtures,
five game-scene comparisons and four open-demo video/PCM comparisons pass;
the eight scene-player diagnostic traces retain recording and validate fully.

Normal r9 manual gameplay is now reported extremely close to full speed, with
only minor ocean walking hitches and remaining ocean/river work. Its 8,925-frame
session logs 18 underruns and one overrun. No candidate is promoted on the basis
of average throughput alone; consistent playback and 5% whole-pipeline margin
remain unfinished.

Evidence: `monomelon-r9-{topology,split-affinity,balanced-affinity,restore-identity}-20261113/`,
including native archives, failed-trace evidence, analysis and cleanup logs.

### Bounded early frame collection: private player candidate

An opt-in player experiment consumes an already completed frame up to 3 ms
before its existing absolute deadline on native DRM GPU output. It adds no
queued frame, leaves deadline advancement unchanged and preserves desktop,
framebuffer and fast-forward behavior. The existing prefetch can consequently
start the following core frame earlier. Twenty-one host tests, four focused
ARM64/QEMU fixtures and 22 native 720-frame runs pass; all observed collection
leads stay within the bound. This is a scheduling experiment, not faster core
processing or a guaranteed reduction in physical display latency.

In the first normal-player batch both control/candidate have zero underruns in
all four saved scenes. Heavier river has 1/1 underruns in the controls versus
2/1 with early collection, with one overrun in each candidate run versus none
in the controls. Instrumented heavy-river modeled p95 improves
17.7709/17.6805→17.2188/17.1826 ms, but its frontend submission-interval p95
worsens 17.9436/17.9231→18.1999/18.4852 ms. Ocean work tails and underruns are
mixed. The lower diagnostic work time does not establish better delivered
cadence or clean audio; leave this private while attributing the audio events.
Evidence: `monomelon-early-ready-20261113/{native-evidence.tar,early-analysis.txt,results-v3-*.txt}`.

A follow-up V4 observer records only counter changes after the main audio pump
and after submission, with bounded storage and no PCM retention or per-frame I/O.
All eight 720-frame traces are complete and their event totals match the final
audio counters. After the 120-frame warm-up, ocean control has 1/2 underruns
(plus one overrun in repeat 2), while early collection has none. However,
heavier-river control has no warmed events in either run; early collection has
an overrun in both, plus three warmed underruns in repeat 2. Thus the mixed
audio result is not only startup behavior. Retain the unchanged production
player. Evidence: `monomelon-early-ready-20261113/audio-events-v4/{native-evidence.tar,event-results.txt}`.

### A55 JIT code-cache maintenance: private core candidate

The imported emitter conservatively cleans and invalidates written code with
`dc civac`, including an A53 erratum workaround. An explicit Linux/A55-only
build option instead uses `dc cvau`, retaining all ranges, instruction-cache
invalidation and ordering barriers. It defaults off and is a deployment
assertion, not CPU detection. All four target cores report A55 r2p0.
[GCC's cache synchronization implementation](https://raw.githubusercontent.com/gcc-mirror/gcc/master/libgcc/config/aarch64/sync-cache.c)
provides a reference for the normal PoU maintenance sequence.

The actual emitter passes repeated generated-code overwrite and in-place patch
checks on every physical core. In two reversed 50,000-iteration microbenchmarks,
emission plus flush plus immediate execution takes 26–34% less CPU for
32–2,048-byte code ranges. This does not mean game frames improve by that much.

The fresh four-open-demo-PGO core (`1c755d9e…`, 271 profile-use compiles) passes
all eight ARM64 fixtures under QEMU and natively, all five saved-scene video/PCM
comparisons and four open-demo comparisons. Two reversed 600-frame uncapped
pairs after 90 warm-up frames nevertheless give ocean r9/candidate
**13.573762 / 13.653797 ms (−0.586%)** and heavier river
**14.934311 / 15.239854 ms (−2.005%)**. Normal-player ocean underruns improve
2/6→0/0; heavy-river counts are mixed at 1/2→2/1, and instrumented work tails
are also mixed. The microbenchmark win is insufficient to establish an overall
promotion; this core remains private and uninstalled. Evidence:
`monomelon-r9-a55-cache-20261113/{micro-native-evidence.tar,native-evidence.tar,results-summary.txt,results-*.txt}`.

### Emitter CLZ and fresh-build calibration: private, not selected

The r9 AArch64 emitter's 64-bit leading-zero loop compiles into a 2,644-byte
logical-immediate classifier. A four-line GCC/Clang builtin substitution retains
zero → 64 and all other-width/compiler fallbacks, shrinking it to 292 bytes.
More than two million helper values, all legal logical immediates and 826,356
emission cases pass; all 12,630,612 generated code bytes match the original.
Native logical-immediate classification drops from roughly 313 to 27 ns per
call. This is a compilation microbenchmark, not a game-frame speedup.

The candidate passes eight ARM64/QEMU and native fixtures, five game-scene
video/PCM comparisons and four open demos. However, a fresh **unchanged r9**
build also changes unrelated function inlining. All builds identify the same
GCC 16.2.1 revision and use the same four open PGO demos; the exact cause of
the profile/build variation is unresolved. Compare against this fresh control
before attributing small whole-game differences to the source patch alone.

Three rotated 600-frame uncapped comparisons after 90 warm-up frames give:

| Core | Ocean mean ms | Heavier-river mean ms |
| --- | ---: | ---: |
| Installed r9 | 13.6225 | 14.9067 |
| Fresh unchanged r9 | 13.6525 | 15.1322 |
| Fresh r9 + CLZ | 13.7277 | 15.2401 |

All nine correctness comparisons pass for the fresh control too. Separate
720-frame runs use the same production-style instrumented player for every
core; audio counts vary and do not establish a repeatable CLZ win. Keep the
installed core. These controls qualify small earlier rebuilt-core comparisons;
they do not negate independently demonstrated accuracy or large/manual gains.
Evidence: `monomelon-r9-emitter-clz-20261113/{native-evidence.tar,elf-audit/report.txt}`
and `monomelon-overnight-20261113/{control-native-evidence.tar,control-results.txt}`.

### Actual display cadence and another affinity layout

A bounded private recorder measures paired atomic ioctls, per-CRTC sequence
and monotonic kernel timestamps, and callback arrival. Six 720-frame native
runs validate without overflow. Both displays report about **60.171 Hz**
(median period **16.619 ms**), versus the game's **59.8261 Hz**. The expected
repeat beat is approximately **2.90 seconds**. This can affect presentation
even when emulation finishes promptly; it does not explain every hitch or
prove an audio fault. No display mode or clock is changed.

Paired kernel event timestamps usually differ by approximately **−0.866 ms**,
but sometimes differ by **+15.77 ms**, one display cycle wider. Wide-phase
pairs after the first 120 frames number 36/2 in river, 0/5 in ocean and 1/32
in heavier river. Atomic submission does not by itself prove simultaneous
physical scanout. These counts do not track audio underruns, and delayed
callback handling is not a measurement of when the display physically flipped.
A separate default-off submission-phase guard is tested below.

A third temporary CPU layout gives the emulation owner CPU0, primary 3D CPU1,
main/middle 3D CPU2 and 2D/shortest 3D CPU3. Ocean modeled p95 improves from
17.99/18.12 to 15.36/15.36 ms, but heavy-river mean worsens from 16.00/15.92
to 16.37/16.12 ms. Ocean underruns are 10/8 versus 8/11; heavy-river 5/4
versus 6/6, with candidate overruns in both heavy runs. Reject promotion.
Transfers finish more than five seconds before the first run; all original
save/binary checks and menu restoration pass. The work model remains a
diagnostic, not proof of the full-pipeline 5% margin.

Evidence: `monomelon-drm-cadence-20261113/{native-evidence.tar,analysis/}` and
`monomelon-r9-spread-affinity-20261113/{native-evidence.tar,work-results.txt}`.

### Paired-phase guard: pairing improves, audio does not

The private guard predicts each CRTC's next blank from validated monotonic
events and requests one bounded sleep before a submission likely to straddle
the pair. It changes no clocks, modes, buffers or queue depth. Host boundary,
mocked callback/submission and lifetime tests pass. Two reversed 720-frame
comparisons per scene use unchanged r9 and otherwise matching recorder players.

| Scene | Control wide-phase pairs after warm-up | Guard wide-phase pairs after warm-up |
| --- | ---: | ---: |
| River | 0 / 6 | 1 / 0 |
| Ocean | 3 / 23 | 1 / 0 |
| Heavier river | 15 / 40 | 0 / 0 |

All six controls have zero warmed audio events. The guard has one warmed
overrun in ocean repeat 1, one in heavy repeat 1, and one underrun in heavy
repeat 2. Requested-wait p95 is approximately 0.45 ms, but observed waits reach
7.42 ms through scheduling; a bounded request is not a bounded elapsed delay.
Keep this private: better paired timestamps do not justify degraded audio,
prove simultaneous physical scanout or close the processing-headroom goal.
All original saves/binaries remain unchanged and the normal menu is restored.
Evidence: `monomelon-drm-phase-guard-20261113/{native-evidence.tar,native-results.txt,work-results.txt}`.

### Direct guest-edge eligibility: measure before linking

A diagnostic counts actual AArch64 dispatch outcomes without installing links.
The first policy allows only already-published, same-mode unconditional immediate
successors in ARM9 DS main RAM. Nine native generated-code/lifecycle fixtures,
five game-scene video/PCM comparisons and four open demos pass. All five
720-frame counter matrices validate their 128 unique rows and outcome sums.

Ready-target coverage of actual ARM9 chained transitions is only **0.01838%
cliff, 0.22260% river, 0.00012% menu, 0.01705% ocean and 0.01219% heavier river**.
Self edges and mutation-disabled transitions are zero. This narrow policy does
not warrant a linker implementation. Conditional exits, sequential fallthroughs
and dynamic branches dominate; their exclusion buckets do not prove they are
safe fixed successors. A broader bounded diagnostic will classify the actual
taken/fallthrough destination before designing any links. Instrumented timings
are not throughput or headroom measurements.
Evidence: `monomelon-r9-edge-eligibility-20261113/{native-evidence.tar,eligibility-summary.txt,analysis/}`.

### Helper-buffer copies: measured optimization target

A default-off diagnostic retains every existing seed and copyback operation.
Separate verification runs compare helper lower-layer interiors before seeding;
timing runs perform no comparison. Seven enabled/six disabled host fixtures,
the retained 826-frame full-buffer oracle, eight ARM64/QEMU/native fixtures,
five game video/PCM comparisons and four open demos pass.

Each outdoor scene has 720 consecutive eligible comparisons with no mismatch.
Inventory has none, because its 3D frames are identical. Two 720-frame player
timing runs per water scene, aligned after 120 player frames, measure:

| Scene | Seed CPU ms/frame, two runs | Copyback CPU ms/frame, two runs |
| --- | ---: | ---: |
| River | 0.2192 / 0.2134 | 0.5179 / 0.4962 |
| Ocean | 0.1966 / 0.2108 | 0.4773 / 0.4561 |
| Heavier river | 0.2162 / 0.1948 | 0.5105 / 0.5182 |

Default bands copy 309,600 seed bytes and 600,624 copyback bytes each frame.
After a completed same-bound banded frame, 297,216 seed bytes already match;
the two boundary rows, all metadata and full copyback must remain. Reset,
restart, helper/bounds changes and nonbanded paths invalidate this opportunity.
A private reuse prototype is being tested. Section costs include instrumentation
and are upper bounds on potential savings, not guaranteed recoverable frame time.
This attribution build intentionally has no PGO; it is not a throughput comparison
against installed r9. Evidence: `monomelon-r9-band-copy-profile-20261113/{native-evidence.tar,native-results.txt}`.

### Integer geometry matrix experiment: isolated result only

The r9 A55 build performs 4×4 matrix products with scalar integer multiply/add
instructions. A private NEON version retains 64-bit modular sums, final shifts
and a scalar fallback for overlapping inputs. An independent modular oracle
checks 100,000 complete-storage cases, including partial overlap, extremes and
unaligned vector loads, under QEMU and natively. Four reversed million-call
native pairs give **127.25–127.37 ns scalar versus 60.67–62.00 ns NEON**, about
**2.05–2.10×** for this routine, including the same test-driver overhead.

That is not a whole-game speedup. The actual emulator integration passes seven
host fixtures; its fresh four-open-demo-PGO build and native game comparison
are still pending. No production code or installed binary is changed.
Evidence: `monomelon-r9-matrix-audit-20261113/{native-evidence.tar,micro-results.txt,r9-matrix.asm}`.

### Inline depth tests: r10 source

The packaged r9 ARM64 rasterizer retains 15 indirect depth-test call sites after
compiler transformations. Candidate `892dd4b0…` replaces the four selected
functions with one small inline predicate, preserving all original call positions
in regular and shadow scanlines. Tolerance and facing are selected once per row;
there are no new renderer fields or duplicated whole-scanline specializations.
The target regular function shrinks from 28,104 to 27,180 bytes and has no
remaining indirect calls.

All six host fixtures pass. The actual predicate matches the original functions
in 16,544,256 boundary, random and signed-extreme comparisons; a tolerance mutant
fails. Separately linked untouched-r9 and candidate renderers match 826 complete
frame fingerprints, including both buffer layers, stencil and shadow history.
The predicate and frame comparisons also pass under ARM64 QEMU and natively.
All four current states, heavier river and four open demos match video/PCM.

Fresh four-open-demo PGO and 600-frame core runs after 90 warm-up frames give:

| Scene | Paired comparisons | R9/candidate core ms |
| --- | ---: | ---: |
| Cliff | 1 | 14.3331 / 14.2382 |
| River | 1 | 13.9367 / 13.6575 |
| Menu | 1 | 7.1010 / 6.9352 |
| Ocean | 3 | 13.6771 / 13.6358 |
| Heavier river | 3 | 15.1028 / 14.9211 |

Heavier river improves in all three core comparisons, about 1.22% overall;
ocean's small aggregate change has mixed signs. Corresponding 720-frame player
comparisons show a modest heavy-river improvement, while ocean's means/tails
vary. Long CPU/JIT and renderer-wait periods remain. This is a candidate for a
further trial, not proof of sustained playback or the required 5% margin.
The change is now published in engine
[`f2b8b7e5`](https://github.com/monofuel/melonDS/commit/f2b8b7e5fae49e0cf786433de12cc9b866b37973)
with a direct predicate regression test, and pinned by wrapper
[`48228a8c`](https://github.com/monofuel/melonds-ds/commit/48228a8cc1a089d0b5fdedb504aeda64ddd01fcc)
for ebuild r10. Its fresh public-source package and eight ARM64 fixtures pass
under QEMU and natively, along with game/open-demo video/PCM comparisons.
The measurements above belong to the prepackage candidate, not an installed-r10
comparison.
Evidence: `monomelon-r9-inline-depth-20261112/`, including
`build-evidence.tar`, `native-evidence.tar`, `followup-evidence.tar` and
`results-*.txt`.

The fresh r10 binary (`7f9727e2…`) does not reproduce the small uncapped gain.
Four paired 600-frame comparisons give ocean **13.6689 / 13.7518 ms** and heavier
river **15.1050 / 15.1128 ms** for r9/r10: −0.603% and effectively flat. Two
paired player comparisons retain lower heavy-river p95 periods
(17.6782/16.9236 to 16.9464/16.8143 ms), but mean work periods are similar and ocean
varies. Correctness passes; the performance tradeoff remains under review, so
r9 stays installed. See `monomelon-package-r10-20261112/` for the public package,
validation/recheck archives and summaries. Neither this small tail improvement
nor the earlier private mean improvement proves the complete goal.

### Packed blending and unrolling: private, not selected

Packed-blend candidate `d8d1a741…` evaluates red/blue in separate 16-bit integer
lanes and green separately. Five-bit source alpha bounds each weighted channel
sum to 2,016, preventing lane carry. Transparent destinations, disabled blending,
destination alpha and unused-bit masking retain their original behavior. ARM64
uses two multiply/two multiply-add instructions rather than three of each.

The six host fixtures, 28,582,912 actual-body/reference comparisons and two
deliberate mutants validate the arithmetic. All 826 original-r9 frame fingerprints
match under QEMU and natively; game/open-demo video/PCM checks also pass. Two
reversed core pairs are essentially flat at ocean and mixed at heavier river;
player timing provides no consistent overall win.

A separate GNU source-file-only experiment disables loop unrolling and peeling
for `GPU3D_Soft.cpp` during both PGO stages. Target option inspection and actual
commands confirm both flags, with existing arithmetic/vectorization flags kept.
The regular function does **not** shrink: 28,104 becomes 28,188 bytes, still with
15 indirect sites. Host fixtures and independent ARM64/native frame/video/PCM
checks pass, but both reversed core pairs are slower.

| Candidate | Ocean r9/candidate ms | Heavier river r9/candidate ms |
| --- | ---: | ---: |
| Packed blend | 13.6945 / 13.7062 | 15.1678 / 15.1176 |
| No unrolling/peeling (`7877cb1f…`) | 13.6106 / 13.8235 | 14.9192 / 15.0925 |

Neither ships. Fewer arithmetic operations or disabling an optimization does not
establish an end-to-end benefit. Evidence:
`monomelon-r9-{packed-blend,no-unroll}-20261112/`, including build/native evidence
archives and paired worktrace summaries. Per-thread instruction/cache counters
are a separate diagnostic; code size alone does not prove cache thrashing.

### r8 clipping fast acceptance

Engine [`1b9c2121`](https://github.com/monofuel/melonDS/commit/1b9c2121492f26709f29d709c1d43de8012e6d56)
avoids three clipping/copy passes when the processed vertices are already inside
the view volume. It preserves colour rounding for all vertices, including strip
reuse; outside/negative-W polygons use the original path. Wrapper
[`213e6eea`](https://github.com/monofuel/melonds-ds/commit/213e6eeab1e34e7f3d0e3ce871b511213fa1e120)
pins that engine. The r8 ebuild changes only source pins.

The private candidate `f0b943c5…` passes the focused differential clipping test,
the existing engine suite and all four native game/four open-demo video/PCM
comparisons. Three rotating comparisons on the independently verified heavier
river checkpoint use the same public-source lightweight-loop player, copied
saves, null output and microphone disabled:

| Core | Core time, mean ms | Player loop, mean ms / 600 frames | Underruns, total | Overruns, total |
| --- | ---: | ---: | ---: | ---: |
| r6 package | 15.6213 | 10,149.0 | 17 | 0 |
| r7 package | 15.5001 | 10,138.7 | 10 | 1 |
| r8 source candidate | 15.1534 | 10,101.3 | 3 | 1 |

That is about 3.09% more core throughput than r6 in this batch. Each candidate
player run has one underrun; the table does not establish clean physical audio
or universal accuracy. The fresh public-source r8 package is installed, core
SHA256 `a24ef7fc353c18bf8a69f6277c6345b724ae829a47086703c7d112a575f3a529`.
It passes all eight native output comparisons, four installed-player smokes and
an explicit r6 rollback smoke. Four slots are migrated through the core API into
`monomelon-r8-lost-in-blue`; original SRAM/states and the microphone-enabled
player remain intact.

Post-installation, one 600-frame run per scene uses the installed package,
90 headless warm-up frames, copied saves and the same lightweight-loop player.
Player timing includes startup/final synchronization; audio uses the null backend
and microphone is disabled. This batch has no paired control and is separate
from the candidate comparison above:

| State | Core time, ms/frame | Player loop, ms / 600 frames | Underruns / overruns |
| --- | ---: | ---: | ---: |
| Cliff | 14.3567 | 10,101 | 0 / 0 |
| River | 13.8008 | 10,095 | 0 / 0 |
| Inventory | 7.0140 | 10,030 | 0 / 0 |
| Ocean | 14.0540 | 10,162 | 3 / 0 |
| Heavier river | 15.2646 | 10,100 | 1 / 0 |

All installed binaries and original/current saves verify unchanged after these
tests; the normal launcher is restored. Manual r8 audio/gameplay acceptance and
the whole-pipeline margin are still pending. There are still ocean/river hitches
to investigate; this is a deployable improvement, not a completed goal.

A private headroom stress test retains normal physical paired GPU output and
audio queueing, adding about 0.796 ms to each core/main stage per frame, with a
matching no-tax control. Initial warmed 600-frame windows pass cliff, river and
inventory at native cadence without underruns; ocean and the heavier river have
underruns under added stress. **The complete goal is still open.** This is an
indirect stress test, not a direct measurement of uncapped work time. Neither
the probe nor its artificial delays are part of shipped builds.

### Renderer follow-ups against r8

Short full-player CPU profiles point at the software renderer. Across all
user-space threads, ocean spends 41.27% of sampled cycles in polygon scanlines,
10.09% in texture lookup and 3.69% in the final scanline pass; heavier river gives
26.90%, 7.05% and 4.41%. These percentages are aggregate CPU attribution, not
exclusive frame time. The heavier river's emulation thread is also near 92% of
one core. There is no evidence here that DDR bandwidth is saturated.

The three 3D workers have uneven CPU use, but changing the existing band split
does not help ocean. Against 96/160's 14.1785 ms core time, 80/144, 80/136 and
64/128 take 15.3800, 15.3905 and 15.4464 ms; steady player underruns rise from one
to three, four and seven. All output checks match. Keep 96/160; aggregate work
balance alone does not predict this pipeline's performance.

Two private source candidates retain all arithmetic and outputs:

- Deferred perspective division: Z-buffered pixels compute the attribute factor
  after depth acceptance; W-buffer depth still computes it first. This was
  previously unhelpful for playback before later main-thread changes. Fresh
  native pairs give ocean core **14.2217 to 13.6542 ms (+4.156%)**, with steady
  underruns **4 to 0**; heavier river **15.0963 to 15.0094 ms (+0.579%)**,
  underruns **0/0**. Two candidate heavy runs each record one overrun.
- Last-texel cache: each polygon remembers its last integer S/T sample's raw
  colour/alpha, with the same discarded fractional bits as the original sampler.
  Polygon setup invalidates it; frame snapshots are immutable and bands have
  private caches. Ocean core **14.1747 to 13.9597 ms (+1.540%)**, heavier river
  **15.0532 to 14.9629 ms (+0.603%)**; both controls/candidates have zero steady
  underruns. One candidate heavy run records an overrun.

These are separate paired batches using copied saves, null audio and microphone
disabled; do not add their gains. Both pass all four native game/four open-demo
video/PCM comparisons. Focused interpolation tests compare over 675 million
values per seed, and a broken preparation step is detected. Cached/uncached
texture tests cover all formats, wrapping, fractional/signed boundaries and
invalidation; that test also passes under ARM64 QEMU.

The combined candidate passes the host suite and all native output checks.
Two full four-state-plus-heavy pairs improve ocean core throughput 3.315% and
heavy 1.220% against their r8 control, with zero candidate steady underruns.
A subsequent direct comparison with deferred-only does not justify the extra
cache, so it stays private. Deferred-only is installed as r9 above; the
microphone-enabled player remains unchanged. Whole-pipeline headroom and manual
acceptance remain separate requirements.

### r7 FIFO routing

Engine [`397f7d4d`](https://github.com/monofuel/melonDS/commit/397f7d4d067ccc9e4e73a00128871422c5ed8fb0)
routes geometry FIFO writes before general bus/register dispatch. It retains
alignment, geometry-power guards and the existing per-word handler; it does not
batch DMA or change emulated timing. Wrapper
[`85fbdd3f`](https://github.com/monofuel/melonds-ds/commit/85fbdd3f40a2d1586c34c70e8d23a739659cf85e)
pins that engine. The r7 ebuild changes only source pins; compiler settings,
other dependencies and the four open PGO workloads are unchanged.

The private candidate has SHA256
`c3477dfb0f34b593129e2f0ff1f5ba0965d1eca00442b3d63d283540d6c4ad86`.
Both changed production files match the published source byte-for-byte.
Scheduler/snapshot/120-frame renderer tests and a new FIFO-routing fixture pass.
The latter compares FIFO aliases, alignment, adjacent registers, power states,
complete FIFO state, IRQ flags, CPU stalls and deadlines against ordinary I/O.
All four saved-game and four open-demo video/PCM sequences match r6 under ARM64
QEMU and natively. This is tested coverage, not universal accuracy proof.

Two alternating native pairs use 600 measured core frames after 90 warm-up
frames, and 600 paced player frames. Same lightweight-loop player, copied saves,
neutral input, null output and microphone disabled for both cores:

| State | Core r6/candidate ms | Core throughput gain | Player r6/candidate speed | Underruns r6/candidate, total |
| --- | ---: | ---: | ---: | ---: |
| Cliff | 15.0006 / 14.5578 | 3.042% | 99.253% / 99.332% | 2 / 1 |
| River | 14.2639 / 13.8949 | 2.656% | 99.371% / 99.362% | 0 / 0 |
| Menu | 7.0128 / 7.0331 | -0.290% | 99.991% / 99.991% | 0 / 0 |
| Ocean | 14.2232 / 14.1495 | 0.521% | 99.199% / 99.322% | 6 / 1 |

A heavier river checkpoint comes from the manually recorded movement sequence;
17 captured images in that sequence match an independent replay. Three paired
runs give core **15.6745 to 15.2357 ms**, about **2.88%** more throughput.
Player-loop means improve **10,153.7 to 10,111.7 ms** for 600 frames; underrun
totals drop **13 to 4**, overruns **1 to 0**. Physical audio acceptance remains
separate. Do not add gains from different batches.

The fresh public-archive r7 package passes all eight native output comparisons
and four normal-player smokes but is **not installed**. Two fresh-package pairs
show a 1.51% heavy-river core gain, with one noisy player run (15 underruns versus
one in its other run). The repeated three-way comparison above adds evidence.
The earlier table measures the private candidate, not the fresh package. Core
capacity alone does not satisfy the goal's 105% whole-pipeline requirement.
A separate player test removes software pacing but keeps every core frame and
normal presentation: overworld images change almost every frame, so actual
vblank waits still cap it near native speed. That test cannot prove the margin.

### Smaller batches and remaining CPU candidates

A same-binary comparison uses the exact r6 core above, changing only
`MONOMELON_BATCH2D` from its default eight lines to four. All four saved
video/PCM sequences match. Two alternating 240-frame pairs on cliff and ocean
use the same private render-ahead player, normal GPU governor and scheduling:

| State | Batch 8 service mean, two runs | Batch 4 service mean, two runs | Batch 8 p95 | Batch 4 p95 |
| --- | ---: | ---: | ---: | ---: |
| Cliff | 16.060 / 15.768 ms | 16.175 / 16.008 ms | 17.658 / 16.593 ms | 17.341 / 18.207 ms |
| Ocean | 16.175 / 15.747 ms | 16.151 / 16.080 ms | 20.190 / 18.311 ms | 20.560 / 19.972 ms |

This service estimate includes core elapsed time, main-thread handoff and next
dispatch delay; it excludes other foreground dependencies and is not a
whole-pipeline capacity measurement. Four-line batches show no consistent win;
the default remains eight. Six-line batches are untested. Evidence:
`monomelon-package-r6-20261112/{batch4-evidence.tar,batch4-results.txt}`.

A separate two-file prototype moves geometry FIFO writes ahead of unrelated
register-switch cases. It retains the geometry-enable checks, write boundaries
and per-word behavior. Fresh four-open-demo PGO passes; all four demo video/PCM
outputs match r6 under ARM64 QEMU. The four saved game scenes also match the
verified native control under desktop QEMU. It subsequently passes all four
native game and all four native demo comparisons. Three alternating 240-frame
pairs use the same render-ahead player and normal CPU/GPU policies:

| State | r6 core capacity | FIFO core capacity | r6 player speed | FIFO player speed |
| --- | ---: | ---: | ---: | ---: |
| Cliff | 110.026% | 111.915% | 97.648% | 98.132% |
| River | 114.619% | 117.854% | 97.976% | 98.096% |
| Menu | 235.720% | 234.774% | 99.709% | 99.632% |
| Ocean | 115.910% | 115.412% | 97.650% | 97.935% |

The cliff/river core gains are 1.72%/2.82%, while ocean and menu do not improve.
Player throughput gains remain below 0.5%. This is not promoted; it does not
close the gap or establish the required headroom. CPU end samples remain
1.992 GHz, temperatures stay below 59 C, and normal launcher/save/binary checks
pass after the batch. Private core SHA256:
`31bcdd63e3b0931103f90d6a802c4df89dd9f719bad000545e180a33b98e8c15`;
evidence: `monomelon-fifo-route-20261112/{build-evidence.tar,native-evidence.tar,results.txt,trace-results.txt}`.

An additional diagnostic counts queued scanlines and inline rendering caused by
live-memory access, display capture or adaptive fallback. On desktop ARM64
QEMU, all four saved scenes match the previously verified native video/PCM
outputs. After 30 warm-up frames, every one of the following 120 frames queues
192 scanlines, with no inline scanlines or adaptive fallback. Cliff frame 149
also has no inline rendering or compilation. This weakens the inline-rendering
hypothesis, but scheduling-dependent fallback still needs native confirmation;
QEMU timings do not measure handheld performance. The known compilation bursts
recur at cliff frame 44 (242 blocks), river frame 100 (244) and ocean frame 36
(249). Diagnostic core SHA256:
`2ddccd1cbec69143d77395e597a00c4f30ac79540ec023e918ad5458afed1b9d`.
Evidence is in private `monomelon-inline-probe-20261112`.

The same diagnostic now passes all four native game output comparisons and
240-frame player traces. After 30 warm-up frames, all four scenes queue 192
scanlines per frame, with zero inline, live-memory, capture or adaptive-fallback
scanlines. Cliff frame 149 still compiles no blocks and draws no lines inline.
Thus inline fallback is ruled out for these tested sequences. Queue-full waits
recur, including two or three in some menu/ocean frames. This motivates a new
64-slot-ring experiment against r6's 32 slots: the earlier negative ring64 test
predates the current parallel 3D renderer. The candidate changes one constant,
keeps eight-line batches and uses fresh open-demo PGO; no gain is assumed before
native output and timing checks. Native diagnostic evidence:
`monomelon-inline-probe-20261112/{native-evidence.tar,native-inline-results.txt}`.

The parallel-renderer ring64 repeat passes all eight native game/demo output
comparisons. Three alternating pairs give core throughput gains of
1.84 / 0.70 / -0.08 / 1.53% for cliff/river/menu/ocean; paired-player gains are
0.21 / 0.10 / -0.15 / 0.45%. This modest result does not justify replacing the
installed r6 package; the experiment remains private. Core SHA256:
`0867fb14aaf4dbb7e0bb52b6e9a8fe5f0530ef365d5eb7f9d35d5d2084fc04b6`.
Evidence: `monomelon-ring64-parallel-20261112/{native-evidence.tar,results.txt,trace-results.txt}`.

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

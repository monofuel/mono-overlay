# monoMelon goal

Play **Lost in Blue at sustained 100% speed in all four save states, with an
extra 5% processing headroom in every state on the Anbernic RG DS Plus**, through
mono-retro-player, with melonDS's emulation and rendering accuracy preserved
and an entirely open-source emulator/frontend stack.

Every state must meet both targets independently: full-speed playback and
105% processing capacity. Fast cliff/menu results cannot offset slow river/ocean
results.

Monofuel reports that the stock NNDDSS emulator runs the game at full speed on
this device, but it is closed source and shows graphical issues. It provides a
performance reference; melonDS remains our accuracy baseline.

## What counts as done

- **All four save states** sustain at least **105% processing capacity**:
  **62.8174 frames/s**, or at most **15.919 ms of work per frame**. This includes
  slot 1 (cliff), slot 2 (river), slot 3 (menu) and slot 4 (ocean).
  Each state must pass independently; averaging results across states does not count.
  Reaching 100% without the extra 5% buffer is progress, but does not meet the goal.
- Normal playback stays paced at **100%**, the game's native **59.8261 frames/s**
  (about **16.715 ms/frame**), with clean audio and no recurring
  hitches, tearing or growing input latency. Average FPS alone is insufficient.
- Verify headroom for the emulator/frontend pipeline, including video and audio
  work. Exclude intentional frame pacing and display-vsync waits when measuring
  processing capacity; do not require a faster display mode. Headless core FPS
  alone does not establish the whole pipeline's 5% margin.
- Both physical displays update together, and controls, touchscreen, saves and
  save states continue working through the normal launcher/player.
- Representative manual gameplay confirms overworld movement, inventory and
  touch interactions; passing the four saved scenes alone is not completion.
- The result builds through the public ebuild from pinned, licensed sources
  without commercial ROMs, private states or game-trained PGO data as build inputs.

## Current baseline

**Installed: r11**, core SHA256
`e1fa23cd2a0f080a2f84c102f0687f9ece8415937c1cae8899e2a9ec5d045b6c`.
The normal launcher uses copied saves under `monomelon-r11-lost-in-blue`; the
original r9 directory is unchanged, and `mono-retro-lost-in-blue-before-r11`
retains the verified r9 core/save path. Four migrated states and this rollback
pass launch checks; the microphone-enabled player is unchanged.

R11 combines r10's inline depth tests with retained software helper buffers,
exact AArch64 NEON matrix multiplication and faster JIT immediate classification.
Its public package gains **2.48% ocean / 2.77% heavy-river core throughput** in
reversed comparisons against r9. All eleven native fixtures, five saved-scene
and four FOSS video/PCM comparisons pass; the package uses pinned public source
and the same four open PGO workloads.

In both reversed normal/added-delay runs, all four standard states have **zero
warmed audio-buffer events**. The diagnostic spins for 1/21 frame period in
each pipeline stage while retaining normal rendering/audio work. Preemption can
reduce actual CPU time because this version uses a wall clock. This supports
the margin target but remains a bounded silent stress test, rather than complete
uncapped-capacity or gameplay acceptance. Startup events remain in some logs;
the extra heavy fixture has one ordinary-run warmed underrun/overrun, while both
taxed repeats are clean. **Manual movement, touch and physical audio validation
are still pending.** The goal remains open; microphone investigation is deferred
to the planned PC test.

A verified 4,910-frame recording of real river gameplay matches all 17 original
reference images on r11, but moving-input audio-buffer events remain. Two reversed
control/added-delay pairs give **1/1 warmed underruns for control**, and **6/1
underruns plus 2/0 overruns with the extra CPU work**, after 120 warm-up frames.
Stationary-scene passes therefore do not establish the complete moving-gameplay
margin. Remaining work includes diagnosing these events and occasional long
emulation-thread frames, alongside the required manual acceptance.

The current test set, updated during manual testing on November 12, is:

- Slot 1: near the cliff, unchanged.
- Slot 2: river near the start; new, important/common gameplay location.
- Slot 3: inventory/menu, the easy control.
- Slot 4: ocean; new.

### Earlier r9 baseline

R9 core SHA256
`1e2bdd76fe1df89931ad94fe1c38d3340289a32cf6944e2c1eff71a63a33ec9a`.
All four states are migrated into separate save copies, with original saves and
an explicit r8 core/launcher rollback retained. The microphone-enabled player
includes Windy's render-ahead presenter; the audio-scheduling prototypes remain
uninstalled.
R9 retains r8's FIFO/clipping improvements and defers perspective division until
a Z-buffered pixel passes its depth test. The fresh public package passes all
eight native output comparisons, four installed player smokes and the r8
rollback check. Earlier 600-frame follow-ups have zero underruns in cliff/river/menu,
one in ocean and five in the heavier moving-river fixture, including startup.
Fresh November 13 production-player runs of 720 frames report three null-backend
underruns in cliff, zero in river/inventory/ocean, and one in the heavier river fixture. Separate
V3 diagnostics put each scene's modeled mean below 15.919 ms, but retain long
individual periods; the model and silent audio runs do not prove the full target.
See [r9 evidence](monomelon-performance.md#r9-deferred-perspective-factors).
Manual r9 gameplay now feels very close to full speed: Monofuel reports only
extremely minor hitching, noticed while walking along the ocean, with some
remaining work around ocean/river areas. This is encouraging acceptance evidence,
but does not establish hitch-free playback or the 5% processing buffer. That
session logs 18 audio underruns and one overrun across 8,925 frames, approximately
149 seconds. Microphone behavior remains unverified in the open-source stack;
the stock emulator's microphone interaction works. An earlier private added-delay stress probe passes cliff,
river and inventory but still exposes ocean/heavier-river underruns; the extra
5% whole-pipeline headroom remains unproven. Its artificial delays are not shipped.

R10's standalone package has mixed performance: heavy-river player tails improve
slightly, while the uncapped mean gain does not repeat. It remains uninstalled;
r11 retains its inline depth-test source in the combined build.

Before this upgrade, Monofuel reported cliff/menu felt full speed while
river/ocean water effects caused noticeable slowdowns. Earlier r5 measurements
of these four states were:

| State | Uncapped core capacity | Paced player speed |
| --- | ---: | ---: |
| Cliff | 104.54% | 95.93% |
| River | 110.90% | 96.71% |
| Menu | 226.66% | 99.09% |
| Ocean | 111.23% | 92.76% |

These use neutral input and silent test audio. Player results include intentional
pacing and therefore do not measure the 105% capacity target. r5 adds ordered
polygon row lists and three-worker software 3D rendering to r4's batched 2D
worker, preserving the existing compiler settings and open-demo PGO. Against
r4 in the same batch, river/ocean player throughput improves 15.82%/59.67%.
The emulation thread and its remaining 2D fences now warrant investigation;
the older single-worker ocean profile is no longer the current critical path.

In that r5 batch, cliff core capacity falls short of 105%, and neither water
scene sustains full speed in the player. These historical core-only and paced
measurements do not establish whole-pipeline headroom. Representative manual
acceptance of the final candidate is pending.
Do not add improvement percentages from separate comparison batches.

The earlier r6 CPU follow-ups are retained in r8.
The newer render-ahead presenter is published in the Windy fork and now installed
with the microphone-enabled player. It overlaps drawing with the previous paired flip.
Four 600-frame r6 runs through that experimental presenter show no null-backend
audio underruns and warmed submissions near native cadence, but recurring long
frames remain even after three seconds of warm-up. Compilation bursts and 2D
fences both contribute. Those earlier measurements precede the microphone-enabled
player deployment. Neither the complete pipeline's 5% buffer nor manual acceptance has
been demonstrated.

Latest manual r6 feedback: cliff, inventory and title screen feel great; river
movement still has significant slowdown. Ocean was not tested in that session.
An exact 4,910-frame input replay runs near native speed on average with both
old and new presenters, but still records audio underruns. Investigate slow
intervals and representative movement; the average does not overturn the manual
report. See [frontend measurements](https://github.com/monofuel/mono-retro/blob/master/docs/player-performance.md#paired-drm-render-ahead-candidate).

See [performance measurements and previous experiments](monomelon-performance.md)
before proposing work. Compiler alternatives, frontend/core overlap and GPU
presentation have already been investigated or implemented; do not assume
they are missing or that an end-to-end timing difference is all removable work.

## Approach and boundaries

- **Start with CPU emulation and software rendering, while keeping GPU options
  open.** If CPU improvements stall or profiling suggests GPU rendering could
  close the gap more effectively, investigate its feasibility, accuracy and
  performance on this device before committing to a larger implementation.
  Keep the existing GPU display presentation.
- Profile the current packaged build and identify work on the frame's critical
  path before choosing optimizations. Consider reducing unnecessary work,
  better data flow, SIMD and parallelism where measurements justify them.
- Prefer general improvements, including architecture-specific fast paths with
  correct portable behavior. Use Lost in Blue as a workload; avoid game-specific
  emulation shortcuts, frameskip, reduced accuracy, overclocking or replacement
  closed-source components.
- Preserve behavior and investigate any video/audio output difference before
  promoting a candidate. Tested sequences provide regression coverage, not proof
  of accuracy across every game and hardware feature.
- Protect original SRAM and states. Use copied test saves, normal state-identity
  checks and a known-good core/launcher rollback. Automated playback is silent;
  manual playback keeps normal audio for detecting timing problems.

## Where work belongs

- [monofuel/melonDS](https://github.com/monofuel/melonDS): emulator engine,
  renderers, JIT and emulated hardware optimizations.
- [monofuel/melonds-ds](https://github.com/monofuel/melonds-ds): libretro integration
  and engine dependency pin.
- [mono-retro](https://github.com/monofuel/mono-retro): frontend scheduling,
  frame/audio transport, input and presentation integration when profiling
  identifies a concrete problem.
- [monoMelon ebuild](../games-emulation/libretro-monomelon): pinned fork commits,
  dependencies, compiler settings and open-demo PGO. Source changes belong in
  the forks. Development work is on `master` in both forks.

Validate candidates with output comparisons separate from timing, alternating
paired performance runs against the current control, and frame-time/audio
observations in the player. Record the actual artifact, workload and result in
the [performance document](monomelon-performance.md). Promote measured wins,
then update the wrapper/ebuild pins and retain rollback; do not promise that a
particular optimization will close the whole gap before measuring it.

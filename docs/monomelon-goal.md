# monoMelon goal

Play **Lost in Blue at 100% speed in each of the four save states, with an extra
5% performance buffer on the Anbernic RG DS Plus**, through
mono-retro-player, with melonDS's emulation and rendering accuracy preserved
and an entirely open-source emulator/frontend stack.

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

The current test set, updated during manual testing on November 12, is:

- Slot 1: near the cliff, unchanged.
- Slot 2: river near the start; new, important/common gameplay location.
- Slot 3: inventory/menu, the easy control.
- Slot 4: ocean; new.

Monofuel reports cliff/menu feel full speed while river/ocean water effects
cause noticeable slowdowns. The installed r5 package's three paired 240-frame
measurements of these four states are:

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

Cliff core capacity still falls short of 105%, and neither water scene sustains
full speed in the player. These short core-only and paced measurements do not
establish whole-pipeline headroom. Representative manual acceptance is pending.
Do not add improvement percentages from separate comparison batches.

Private follow-ups improve uncapped core throughput by about 4–6% and overlap
display rendering with the previous paired flip. Warmed core submissions average
near the native cadence, but recurring long frames remain, particularly around
ocean rendering and frame handoff. These candidates are not installed and have
not demonstrated the complete pipeline's 5% buffer or manual acceptance.

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

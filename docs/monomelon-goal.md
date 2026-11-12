# monoMelon goal

Play **Lost in Blue at full speed on the Anbernic RG DS Plus**, through
mono-retro-player, with melonDS's emulation and rendering accuracy preserved
and an entirely open-source emulator/frontend stack.

Monofuel reports that the stock NNDDSS emulator runs the game at full speed on
this device, but it is closed source and shows graphical issues. It provides a
performance reference; melonDS remains our accuracy baseline.

## What counts as done

- All three saved outdoor scenes sustain the game's native **59.8261 frames/s**
  (about **16.715 ms/frame**) in uncapped capacity tests. Inventory retains
  full-speed capacity.
- Normal playback maintains full game speed with clean audio and no recurring
  hitches, tearing or growing input latency. Average FPS alone is insufficient.
- Both physical displays update together, and controls, touchscreen, saves and
  save states continue working through the normal launcher/player.
- Representative manual gameplay confirms overworld movement, inventory and
  touch interactions; passing the three saved scenes alone is not completion.
- The result builds through the public ebuild from pinned, licensed sources
  without commercial ROMs, private states or game-trained PGO data as build inputs.

## Current baseline

The current test set, updated during manual testing on November 12, is:

- Slot 1: near the cliff, unchanged.
- Slot 2: river near the start; new, important/common gameplay location.
- Slot 3: inventory/menu, the easy control.
- Slot 4: ocean; new.

Monofuel reports cliff/menu feel full speed while river/ocean water effects
cause noticeable slowdowns. The following measurements use the **previous**
two-outdoor-scene set; do not reuse old slot-2 results for the river or infer
the new ocean scene's performance. Capture a fresh baseline for all four slots.

`games-emulation/libretro-monomelon-1.4.0-r4` builds our engine and wrapper forks
with the existing compiler, open-demo PGO, exact ARM64 rasterizer changes and
batched 2D rendering on a worker. Its first three paired package runs measure
**97.35% / 98.66% overworld speed**, with inventory near 100%. Closing that
playback gap requires roughly **2.72% / 1.36% more throughput**, or
**0.45 / 0.23 ms less per frame**. These are short neutral-input measurements;
manual full-speed acceptance remains incomplete, especially around water.

Uncapped core capacity is **99.65% / 116.47%** in the overworlds, so scene 1
also needs consistent core headroom. The former r3 baseline was
**82.58% / 86.47%** across ten paired runs per scene. Do not add improvement
percentages from separate comparison batches.

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

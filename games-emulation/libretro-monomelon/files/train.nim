# Copyright 2026 mono-overlay contributors
# SPDX-License-Identifier: MIT

import
  std/[dynlib, os, strutils, tables]

type
  GameInfo {.bycopy, importc: "struct retro_game_info", header: "libretro.h".} = object
    path: cstring
    data: pointer
    size: csize_t
    meta: cstring
  Variable {.bycopy, importc: "struct retro_variable", header: "libretro.h".} = object
    key, value: cstring
  LogCallback {.bycopy, importc: "struct retro_log_callback", header: "libretro.h".} = object
    log: pointer
  Environment = proc(command: cuint, data: pointer): bool {.cdecl.}
  Video = proc(data: pointer, width, height: cuint, pitch: csize_t) {.cdecl.}
  Audio = proc(left, right: int16) {.cdecl.}
  AudioBatch = proc(data: ptr int16, frames: csize_t): csize_t {.cdecl.}
  Poll = proc() {.cdecl.}
  Input = proc(port, device, index, id: cuint): int16 {.cdecl.}

const
  Experimental = 0x10000'u32
  GetCanDupe = 3'u32
  Shutdown = 7'u32
  SetPerformanceLevel = 8'u32
  GetSystemDirectory = 9'u32
  SetPixelFormat = 10'u32
  SetInputDescriptors = 11'u32
  GetVariable = 15'u32
  SetVariables = 16'u32
  GetVariableUpdate = 17'u32
  SetSupportNoGame = 18'u32
  GetLogInterface = 27'u32
  GetSaveDirectory = 31'u32
  SetControllerInfo = 35'u32
  SetGeometry = 37'u32
  GetAudioVideoEnable = 47'u32 or Experimental
  GetInputBitmasks = 51'u32 or Experimental
  GetCoreOptionsVersion = 52'u32
  JoypadDevice = 1'u32
  JoypadMask = 256'u32
  PixelSampleStep = 13
  FramesPerButton = 30
  TrainingButtons = [7, 6, 4, 5, 8, 0, 10, 11]

var
  directory, failure: string
  variables: Table[string, string]
  frame, videoFrames, nonUniformFrames: int
  stopped: bool
  pixelFormat: cint

{.emit: """
#include <stdarg.h>
#include <stdio.h>
#include "libretro.h"
static void monomelon_log(enum retro_log_level level, const char *format, ...) {
  va_list args;
  va_start(args, format);
  vfprintf(stderr, format, args);
  va_end(args);
}
""".}

proc coreLog(level: cint, format: cstring) {.cdecl, varargs, importc: "monomelon_log", nodecl.}

proc environment(command: cuint, data: pointer): bool {.cdecl.} =
  ## Supply software rendering, built-in system data and fixed core options.
  try:
    case command
    of GetCanDupe:
      cast[ptr bool](data)[] = true
      return true
    of Shutdown:
      stopped = true
      return true
    of SetPerformanceLevel, SetInputDescriptors, SetSupportNoGame, SetControllerInfo, SetGeometry:
      return true
    of GetSystemDirectory, GetSaveDirectory:
      cast[ptr cstring](data)[] = directory.cstring
      return true
    of SetPixelFormat:
      pixelFormat = cast[ptr cint](data)[]
      return pixelFormat in [0.cint, 1.cint, 2.cint]
    of GetVariable:
      let variable = cast[ptr Variable](data)
      if variables.hasKey($variable.key):
        variable.value = variables[$variable.key].cstring
        return true
      variable.value = nil
    of SetVariables:
      let options = cast[ptr UncheckedArray[Variable]](data)
      var index = 0
      while options[index].key != nil:
        let
          key = $options[index].key
          description = $options[index].value
          separator = description.find(';')
        if separator < 0: raise newException(ValueError, "Malformed core option: " & key)
        let values = description[separator + 1 .. ^1].strip().split('|')
        variables[key] = values[0]
        case key
        of "melonds_threaded_renderer", "melonds_jit_enable": variables[key] = "enabled"
        of "melonds_jit_fast_memory": variables[key] = "disabled"
        of "melonds_screen_layout1": variables[key] = "top-bottom"
        of "melonds_screen_gap": variables[key] = "0"
        of "melonds_mic_input": variables[key] = "silence"
        else: discard
        if variables[key] notin values:
          raise newException(ValueError, "Unsupported training option: " & key)
        inc index
      return true
    of GetVariableUpdate:
      cast[ptr bool](data)[] = false
      return true
    of GetLogInterface:
      cast[ptr LogCallback](data).log = cast[pointer](coreLog)
      return true
    of GetAudioVideoEnable:
      cast[ptr cint](data)[] = 3
      return true
    of GetInputBitmasks:
      return true
    of GetCoreOptionsVersion:
      cast[ptr cuint](data)[] = 0
      return true
    else: discard
  except CatchableError as error:
    # Keep Nim exceptions on the Nim side of the callback boundary.
    failure = error.msg

proc video(data: pointer, width, height: cuint, pitch: csize_t) {.cdecl.} =
  ## Check that the workload produces nonuniform software frames without a display.
  if data == nil: return
  if width == 0 or height == 0 or pitch == 0:
    failure = "Invalid video frame"
    return
  inc videoFrames
  let
    bytesPerPixel = if pixelFormat == 1: 4 else: 2
    pixels = cast[ptr UncheckedArray[uint8]](data)
    first = pixels[0]
  for y in countup(0, height.int - 1, PixelSampleStep):
    for x in countup(0, width.int - 1, PixelSampleStep):
      if pixels[y * pitch.int + x * bytesPerPixel] != first:
        inc nonUniformFrames
        return

proc audio(left, right: int16) {.cdecl.} =
  ## Consume generated sound without opening an audio device.
  discard

proc audioBatch(data: ptr int16, frames: csize_t): csize_t {.cdecl.} =
  ## Acknowledge all generated sound without retaining it.
  frames

proc poll() {.cdecl.} =
  ## Keep input fixed throughout each emulated frame.
  discard

proc input(port, device, index, id: cuint): int16 {.cdecl.} =
  ## Exercise existing demo controls without pressing Start or Select.
  if port != 0 or device != JoypadDevice or index != 0: return 0
  let button = TrainingButtons[(frame div FramesPerButton) mod TrainingButtons.len]
  if id == JoypadMask: return cast[int16](1'u16 shl button)
  if id.int == button: return 1

proc main() =
  ## Run one open-source training ROM for a fixed number of frames.
  if paramCount() != 4:
    raise newException(ValueError, "Usage: monomelon-train CORE ROM WORK_DIRECTORY FRAMES")
  let
    core = loadLib(paramStr(1))
    romPath = absolutePath(paramStr(2))
    romData = readFile(romPath)
    frames = parseInt(paramStr(4))
  directory = absolutePath(paramStr(3))
  if core == nil: raise newException(IOError, "Cannot load core: " & paramStr(1))
  defer: unloadLib(core)
  if frames < 120: raise newException(ValueError, "Training requires at least 120 frames")
  createDir(directory)
  template symbol(name: string, kind: typedesc): untyped =
    block:
      let address = symAddr(core, name)
      if address == nil: raise newException(IOError, "Missing libretro symbol: " & name)
      cast[kind](address)
  symbol("retro_set_environment", proc(callback: Environment) {.cdecl.})(environment)
  symbol("retro_set_video_refresh", proc(callback: Video) {.cdecl.})(video)
  symbol("retro_set_audio_sample", proc(callback: Audio) {.cdecl.})(audio)
  symbol("retro_set_audio_sample_batch", proc(callback: AudioBatch) {.cdecl.})(audioBatch)
  symbol("retro_set_input_poll", proc(callback: Poll) {.cdecl.})(poll)
  symbol("retro_set_input_state", proc(callback: Input) {.cdecl.})(input)
  symbol("retro_init", proc() {.cdecl.})()
  defer: symbol("retro_deinit", proc() {.cdecl.})()
  var game = GameInfo(path: romPath.cstring, data: unsafeAddr romData[0], size: romData.len.csize_t)
  if not symbol("retro_load_game", proc(game: ptr GameInfo): bool {.cdecl.})(addr game):
    raise newException(IOError, "Core rejected training ROM: " & romPath)
  defer: symbol("retro_unload_game", proc() {.cdecl.})()
  let run = symbol("retro_run", proc() {.cdecl.})
  for index in 0 ..< frames:
    frame = index
    run()
    if failure.len > 0: raise newException(IOError, failure)
    if stopped: raise newException(IOError, "Training ROM requested shutdown")
  if nonUniformFrames < frames div 2:
    raise newException(IOError, "Training ROM did not produce enough nonuniform frames")
  echo "TRAINED ", romPath.extractFilename, " frames=", frames,
    " video=", videoFrames, " nonuniform=", nonUniformFrames

when isMainModule:
  main()

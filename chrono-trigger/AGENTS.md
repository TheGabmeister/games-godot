# AGENTS.md

Guidance for coding agents working in this repository.

## Project Overview

This is a Godot 4.6 project that recreates Chrono Trigger gameplay systems as a scalable architecture exercise. It is not trying to reproduce the full game content. Use `SPEC.md` as the reference for complete systems, and use the implementation phase docs to decide current scope.

- `IMPL.md` defines the 10 playable implementation phases.
- `IMPL_01.md` describes Phase 1, which is currently implemented.
- `IMPL_02.md` describes the next planned phase: one-on-one field battle.
- `CLAUDE.md` contains parallel agent guidance; keep this file aligned with it when project conventions change.

## Engine And Tools

- Godot executable: `D:/Godot_v4.6.2-stable_win64.exe`
- Engine target: Godot 4.6
- Primary language: GDScript
- Main scene: `res://scenes/debug_room.tscn`
- Viewport: 1200x900, stretch mode `canvas_items`
- Renderer: GL Compatibility
- Physics config includes Jolt for 3D, though gameplay is 2D top-down.

Useful validation commands:

```powershell
& "D:/Godot_v4.6.2-stable_win64.exe" --path . --headless --quit
& "D:/Godot_v4.6.2-stable_win64.exe" --path . --import --headless
```

Use the import command when adding or changing resources that need Godot to register generated metadata or `class_name` types.

## Repository Layout

```text
res://
  dialogue/    DialogueData .tres resources
  docs/        Companion reference tables
  enemies/     Enemy data and enemy assets, beginning in Phase 2
  npc/         NPC sprites and audio
  player/      Player sprites, SpriteFrames resources, and audio
  props/       Environment sprites and audio
  scenes/      .tscn scene files
  scripts/     .gd scripts
  tools/       Asset export and generation scripts
```

Keep scripts in `scripts/` and scenes in `scenes/`. Keep sprites and audio beside their owning entity folder unless the repo establishes a more specific pattern.

## Architecture Conventions

- `GameState` is an autoload at `scripts/game_state.gd`.
- Gameplay scripts should gate input and behavior on `GameState.current`.
- State changes should go through `GameState.change(new_state)` so listeners receive `state_changed`.
- Field interaction uses the player's `InteractRay`; interactable nodes join the `interactable` group and implement `interact()`.
- Author structured data as Godot `Resource` files when the phase needs repeatable content, for example `DialogueData` and `EnemyData`.
- Prefer the simplest implementation that satisfies the active phase. Avoid future-proof systems until a phase explicitly needs them.

## Style And Scope

- Use SNES-original names, not DS retranslation names.
- v1 scope is SNES content only; DS additions are stretch goals.
- Keep changes local and phase-sized.
- Favor KISS, YAGNI, and DRY when there is real duplication.
- Do not refactor unrelated systems while implementing a phase task.
- Do not manually edit generated `.uid` files unless there is a clear Godot-specific reason.
- Keep files ASCII unless the existing file already uses another character set or the content requires it.

## Assets

Sprites are authored as SVG and exported to PNG with Inkscape. Character sprite cells are 64x64 px, usually arranged as horizontal strips.

Batch export:

```powershell
bash tools/export_sprites.sh
```

Configured external tools:

- Inkscape: `/c/Program Files/Inkscape/bin/inkscape.exe`
- rfxgen: `D:/rfxgen_v5.0_win_x64/rfxgen.exe`
- FluidSynth: `D:/fluidsynth-v2.5.4-win10-x64-cpp11/bin/fluidsynth.exe`
- ffmpeg: `D:/ffmpeg-8.1-essentials_build/bin/ffmpeg.exe`
- SoundFont: `D:/GeneralUser-GS/GeneralUser-GS.sf2`
- Python: `C:/Users/Admin/AppData/Local/Python/pythoncore-3.14-64/python.exe`

Python scripts in `tools/music/` use `midiutil` to generate MIDI → FluidSynth renders with a soundfont to WAV → ffmpeg converts to OGG.

## Implementation Workflow

1. Read the active phase document before coding.
2. Check `SPEC.md` and companion docs only for the systems touched by the task.
3. Make the smallest playable vertical slice that satisfies the phase checklist.
4. Run Godot headless validation before finishing when scripts, scenes, resources, or project settings changed.
5. Update the relevant phase checklist if the task completes a documented item.

For Phase 2 work, read `IMPL_02.md` first. It defines the expected `BATTLE` state, enemy encounter, ATB loop, battle UI, enemy data resource, battle music, and test checklist.

## Current Baseline

Phase 1 is implemented:

- Crono can move in 8 directions in the debug room.
- Camera follows the player.
- NPC interaction opens a typewriter dialogue box.
- Movement is locked during dialogue.
- `GameState` currently includes `FIELD` and `DIALOGUE`.

Phase 2 is planned but not yet complete.

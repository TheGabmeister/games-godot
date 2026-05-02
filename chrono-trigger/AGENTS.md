# AGENTS.md

Guidance for coding agents working in this repository.

## Project Overview

This is a Godot 4.6 project that recreates Chrono Trigger gameplay systems as a scalable architecture exercise. It is not trying to reproduce the full game content. Use `SPEC.md` as the reference for complete systems, and use the implementation phase docs to decide current scope.

- `IMPL.md` defines the 10 playable implementation phases.
- Completed phase specs live in `docs/impl/`.
- `IMPL_04.md` is the active phase spec: Single Techs, elements, statuses, MP, and TP learning.
- `CLAUDE.md` contains parallel agent guidance; keep this file aligned with it when project conventions change.

## Engine And Tools

- Godot executable: `D:/Godot_v4.6.2-stable_win64.exe`
- Engine target: Godot 4.6
- Primary language: GDScript
- Main scene: `res://scenes/gameplay.tscn`
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
  docs/        Companion reference tables and completed phase specs
  enemies/     Enemy data and enemy sprites
  items/       ItemData .tres resources
  music/       Music source and rendered audio
  npc/         NPC sprites and audio
  party/       CharacterData resources and party member sprites
  player/      Player/Crono sprites and audio
  props/       Environment sprites and audio
  scenes/      .tscn scene files
  scripts/     .gd scripts
  tools/       Asset export and generation scripts
```

Phase 4 will add `techs/` for `TechData` resources, grouped by character (`techs/crono/`, `techs/marle/`, `techs/lucca/`). Keep scripts in `scripts/` and scenes in `scenes/`. Keep sprites and audio beside their owning entity folder unless the repo establishes a more specific pattern.

## Architecture Conventions

- `GameState` is an autoload at `scripts/game_state.gd`.
- `MusicManager` is an autoload at `scripts/music_manager.gd`.
- Gameplay scripts should gate input and behavior on `GameState.current`.
- State changes should go through `GameState.change(new_state)` so listeners receive `state_changed`.
- Current game states include `FIELD`, `DIALOGUE`, and `BATTLE`; add new states only when a phase needs them.
- `scenes/gameplay.tscn` owns gameplay-scoped systems: `PartyManager`, `BattleManager`, `Inventory`, `BattleUI`, `DialogueBox`, and the current level instance.
- Gameplay systems register in groups named by `scripts/groups.gd`; prefer group lookups over hard-coded scene paths.
- Field interaction uses the player's `InteractRay`; interactable nodes join the `interactable` group and implement `interact()`.
- Author structured data as Godot `Resource` files when the phase needs repeatable content, for example `DialogueData`, `CharacterData`, `EnemyData`, `ItemData`, and Phase 4 `TechData`.
- Treat `.tres` resources as immutable definitions during play. Copy runtime state into managers such as `PartyManager` and `BattleManager`.
- Prefer the simplest implementation that satisfies the active phase. Avoid future-proof systems until a phase explicitly needs them.

## Battle Conventions

- `PartyManager` owns persistent party runtime state across battles.
- `BattleManager` copies party and enemy state on battle start, runs ATB/combat resolution, and writes persistent party state back on victory or escape.
- `BattleUI` is signal-driven from `BattleManager`; extend existing signals and menu states rather than introducing direct scene coupling.
- Existing combat supports 3 party members, multi-enemy encounters, Attack/Item commands, ally/enemy target selection, Wait/Active mode, escape, battle music, victory, and game over.
- Encounter groups are driven by enemies with matching `encounter_group` values.

For Phase 4, preserve the Phase 3 flow while adding MP, Tech command/menu handling, magic damage, element resistance, status tracking, and TP learning.

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

Python scripts in `tools/music/` use `midiutil` to generate MIDI, FluidSynth renders with a soundfont to WAV, and ffmpeg converts to OGG.

## Implementation Workflow

1. Read the active phase document before coding. For current work, start with `IMPL_04.md`.
2. Check `SPEC.md` and companion docs only for the systems touched by the task.
3. Make the smallest playable vertical slice that satisfies the phase checklist.
4. Run Godot headless validation before finishing when scripts, scenes, resources, or project settings changed.
5. Update the relevant phase checklist if the task completes a documented item.
6. When a phase is completed, move its `IMPL_XX.md` into `docs/impl/`, update the active phase note here and in `CLAUDE.md`, and leave the next phase spec at the project root.

For Phase 4 work, read `IMPL_04.md` first. It defines the expected MP additions, `TechData` resource, Single Tech data, element resistance model, status framework, Battle UI changes, battle manager flow, Blue Imp debug encounter, and test checklist.

## Current Baseline

Phases 1-3 are implemented:

- Phase 1: Crono movement, camera follow, NPC interaction, typewriter dialogue, and dialogue movement lock.
- Phase 2: field-to-battle transition, ATB battle, physical damage formula, battle UI, battle music, victory, and game over.
- Phase 3: 3-member party, multi-enemy encounters, ATB ready queue, Attack/Item commands, target selection, escape mechanic, Wait/Active mode, Inventory, snake formation followers, and gameplay scene wrapper.

Phase 4 is the active implementation phase. Phases 5-10 are spec-only.

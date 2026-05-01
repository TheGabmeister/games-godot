# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A Godot 4.6 project recreating Chrono Trigger's gameplay systems. The goal is scalable architecture — not a full content recreation. SPEC.md documents the complete game systems as a reference; implementation will be selective. IMPL.md defines 10 implementation phases; each phase has its own IMPL_XX.md with detailed specs and test checklists.

## Engine & Config

- **Godot 4.6** — executable at `D:/Godot_v4.6.2-stable_win64.exe`
- **GDScript** is the primary language
- GL Compatibility renderer, D3D12 on Windows
- Viewport: 1200×900, stretch mode `canvas_items`
- Physics: Jolt Physics (3D configured, but the game is 2D top-down)

## Running the Project

```bash
# Run the game
"D:/Godot_v4.6.2-stable_win64.exe" --path .

# Headless check for errors
"D:/Godot_v4.6.2-stable_win64.exe" --headless --quit

# Force reimport (registers class_name types)
"D:/Godot_v4.6.2-stable_win64.exe" --import --headless
```

## Architecture

### GameState autoload

`GameState` (scripts/game_state.gd) is the central state machine. All input-handling scripts gate on `GameState.current` to determine whether they should respond.

```
enum State { FIELD, DIALOGUE }  — expanded each phase (BATTLE, MENU, CUTSCENE...)
```

State transitions go through `GameState.change(new_state)` which emits `state_changed`.

### Interaction pattern

Player has a RayCast2D (`InteractRay`) pointing in the facing direction. On interact press, if the ray hits a node in the `"interactable"` group, it calls `collider.interact()`. NPCs/objects add themselves to this group and implement `interact()`.

### Resources as data

Game data is authored as Godot Resource `.tres` files:
- `DialogueData` — speaker name + lines array (dialogue/)
- `EnemyData` — enemy stats, rewards (enemies/, Phase 2)

### Folder structure

```
res://
├── dialogue/    — DialogueData .tres files
├── enemies/     — EnemyData .tres files + enemy sprites
├── npc/         — NPC sprites and audio
├── player/      — Player sprites and audio
├── props/       — Environment/tilemap sprites and audio
├── scenes/      — All .tscn scene files
├── scripts/     — All .gd script files
├── tools/       — Asset export scripts
└── docs/        — Spec companion files
```

Sprites and audio live alongside their entity (player/, npc/, enemies/). Scripts and scenes are centralized in their own folders.

## Spec Documentation

- **SPEC.md** — master spec: systems, characters, story, items, equipment, economy, engine/presentation, progression flags
- **docs/techs.md** — Single/Dual/Triple Tech tables with TP thresholds, MP costs, elements, targeting
- **docs/bestiary.md** — enemy stat tables + regular enemy behavior patterns
- **docs/boss-ai.md** — per-boss AI: attack lists, phase transitions, counter triggers, kill orders

When implementing a system, read the relevant SPEC.md section first, then the companion docs/ file for data tables. SPEC.md §11 lists open questions needing ROM-data verification.

## Conventions

- SNES-original names throughout (not DS retranslations)
- v1 scope is SNES content only; DS-port additions are stretch goals
- **KISS** — simplest thing that works
- **YAGNI** — don't build for hypothetical needs
- **DRY** — remove real duplication, not shape-similar code
- **Locality of change** — adding a new entity or feature should touch as few files as possible

## Asset Pipeline

- **Sprites**: SVG source files exported to PNG via Inkscape. Sprite size is 64×64 px. Sprite sheets are horizontal strips (e.g., 512×64 for 8 frames).
  - Inkscape path: `"/c/Program Files/Inkscape/bin/inkscape.exe"`
  - Batch export: `bash tools/export_sprites.sh` (re-exports all SVGs)
- **Sounds**: generate with rfxgen (`"D:/rfxgen_v5.0_win_x64/rfxgen.exe" -g coin -o sound.wav`)
- **Music**: Python scripts in `tools/music/` use `midiutil` to generate MIDI → FluidSynth renders with a soundfont to WAV → ffmpeg converts to OGG. Tool paths: `D:/fluidsynth-v2.5.4-win10-x64-cpp11/bin/fluidsynth.exe`, `D:/ffmpeg-8.1-essentials_build/bin/ffmpeg.exe`, soundfont `D:/GeneralUser-GS/GeneralUser-GS.sf2`

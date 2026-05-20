# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Final Fantasy I Pixel Remaster systems recreation in Godot 4.6. The goal is to build scalable gameplay systems (combat, magic, equipment, progression, world traversal) with enough content to validate each system — not a full game recreation. See SPEC.md for the gameplay systems spec and PHASES.md for the 14-phase implementation plan.

When implementing a phase, read both SPEC.md and PHASES.md. The spec has the formulas and numbers; the phases have the build order and scope boundaries.

## Engine & Tools

- **Godot 4.6.2** (Forward Plus rendering, D3D12 driver)
- Run Godot CLI: `Godot_v4.6.2-stable_win64.exe` (on PATH — do not use the full path)
- **Inkscape** for sprite pipeline: create SVG source → export to PNG via `inkscape input.svg --export-type=png --export-filename=output.png -w <width> -h <height>`
- **ffmpeg:** `D:\Tools\ffmpeg-8.1-essentials_build\bin\ffmpeg.exe`
- **fluidsynth:** `D:\Tools\fluidsynth-v2.5.4-win10-x64-cpp11\bin\fluidsynth.exe` (flags before soundfont/MIDI: `fluidsynth -ni -F out.wav -r 44100 soundfont.sf2 input.mid`)
- **Blender:** `"C:\Program Files\Blender Foundation\Blender 5.1\blender.exe"`
- **8-bit soundfont:** `D:\Tools\8bitsf.SF2`

If `where <tool>` fails in the Bash shell, use the full paths above — shell sessions may not inherit the latest user PATH.

## Running the Project

```bash
# Run the game (starts at title screen)
Godot_v4.6.2-stable_win64.exe --path . --run

# Run a specific scene
Godot_v4.6.2-stable_win64.exe --path . --run res://path/to/scene.tscn

# Force reimport assets (needed after adding new PNGs/OGGs externally)
Godot_v4.6.2-stable_win64.exe --path . --headless --import

# Export (headless)
Godot_v4.6.2-stable_win64.exe --path . --headless --export-release "Windows Desktop"
```

## Resolution

- **Base viewport:** 1280x720 (stretch mode `viewport`)
- **Tile size:** 64x64 px (20x11 visible tile grid)
- **Character sprites:** 64x96 px (1 tile wide, 1.5 tiles tall)
- **NPC sprites:** 64x96 px (single front-facing idle)

## Architecture

### Autoloads (initialization order)

1. **GameState** (`scripts/autoloads/game_state.gd`) — State machine with enum `State { TITLE, FIELD, DIALOGUE, BATTLE, CUTSCENE, MENU }`. All scripts gate input with `GameState.is_state()`. Transitions via `GameState.transition()`, emits `state_changed` signal.
2. **DialogueData** (`scripts/dialogue_data.gd`) — Loads and caches JSON dialogue files from `data/dialogue/`. Called with `DialogueData.get_dialogue(path, id)`.
3. **MusicManager** (`scripts/autoloads/music_manager.gd`) — Single-track music on "Music" audio bus. `play(stream)` prevents restarting same track. Auto-loops.
4. **SfxManager** (`scripts/autoloads/sfx_manager.gd`) — Pool of 16 AudioStreamPlayers on "SFX" audio bus. `play(stream, volume_db)`.
5. **PartyData** (`scripts/autoloads/party_data.gd`) — Holds party array of `CharacterData` objects with Level 1 stats. `enum Job { WARRIOR, MONK, WHITE_MAGE, BLACK_MAGE }`.

### Scene flow

`title_screen.tscn` → (confirm) → `cornelia_town.tscn` ↔ (door trigger) ↔ `cornelia_castle.tscn`

### Key scenes

- **`_scenes/warrior.tscn`** — Player character (CharacterBody2D, collision layer 2 + AnimatedSprite2D + InteractArea). Script: `player_movement.gd`. Only processes in FIELD state.
- **`_scenes/npc.tscn`** — Reusable NPC template (StaticBody2D). Exports: `sprite_texture`, `dialogue_file`, `dialogue_id`. Loads dialogue from JSON on `_ready()`. Has `interact()` method called via duck typing.
- **`_scenes/dialogue_box.tscn`** — CanvasLayer (layer 10) with character-by-character text reveal + SFX. `class_name DialogueBox`. Emits `dialogue_finished` signal.
- **`_scenes/door_trigger.tscn`** — Reusable Area2D (collision layer 4, mask 2). Exports: `target_scene_path`, `spawn_position`. Transitions scenes on player body enter, sets spawn override on GameState.
- **Level scenes** (`cornelia_town.tscn`, `cornelia_castle.tscn`) — All use `scripts/level.gd` with `@export var music: AudioStream`. Tiles painted in editor (TileMapLayer `tile_map_data`). Level.gd handles FIELD state transition, music playback, and spawn position override.

### Gameplay node instantiation

`level.gd` auto-creates three nodes on `_ready()`: Warrior (from `warrior.tscn`), Camera2D (limits derived from TileMapLayer used rect), and DialogueBox (from `dialogue_box.tscn`). Level scenes should NOT contain these nodes — only TileMapLayer, NPCs, and door triggers.

### Interactable system

NPCs (and future interactables) use duck typing via `Groups.INTERACTABLE` (`scripts/groups.gd`). The NPC's `InteractionArea` (Area2D child) is in the `"interactable"` group. The player finds the nearest interactable facing them and calls `target.call(&"interact")`. Each interactable implements its own `interact()` method — NPCs open dialogue, future objects (chests, signs) do their own thing.

### Input handling pattern

Scripts check `GameState.is_state()` at the top of `_physics_process` and `_input`. The player transitions FIELD → DIALOGUE when talking to NPCs, and back to FIELD when dialogue finishes. Discrete actions use `_input()`, continuous movement uses `_physics_process()`. Consume events with `get_viewport().set_input_as_handled()`.

### Collision layers

| Layer | Name | Purpose |
|-------|------|---------|
| 1 | World | Tile collision, walls, NPC bodies |
| 2 | Player | Player CharacterBody2D |
| 3 | NPC Interaction | NPC dialogue trigger areas |
| 4 | Triggers | Door transitions, zone triggers |

### Audio buses

`Master` → `Music` (MusicManager) + `SFX` (SfxManager). Defined in `default_bus_layout.tres`.

## Asset Pipelines

### Sprites

Character sprite sheets: 192x384 PNG (3 columns × 4 rows: idle/walk1/walk2 × down/left/right/up). Generator: `scripts/gen_sprites.py`. SVG sources kept alongside PNGs in `characters/<name>/`. SpriteFrames `.tres` files use AtlasTexture regions from the sheet.

NPC sprites: single 64x96 PNGs in `characters/npcs/`.

### Tiles

Tileset atlas: 512x256 PNG (8×4 grid of 64x64 tiles). Generator: `tilesets/gen_tiles.py`. Tileset resource: `tilesets/cornelia_tileset.tres` with physics polygons on impassable tiles.

### Music

Python script `music/gen_music.py` generates MIDI via `midiutil`. Render pipeline: Python → MIDI → fluidsynth (with 8bitsf.SF2) → WAV → ffmpeg → OGG. Only the `.py` and `.ogg` files are kept; `.mid` and `.wav` are intermediates.

### SFX

Generated via ffmpeg synthesis filters (`sine`, `lavfi`). Output as OGG in `ui/`. No generator script — created via one-off commands.

### Dialogue

JSON files in `data/dialogue/` (one per area). Structure: `{ "id": { "name": "NPC Name", "lines": ["..."] } }`. NPCs reference these via `dialogue_file` and `dialogue_id` exports.

## Conventions

- Scenes in `_scenes/` (underscore prefix for editor sorting)
- Autoloads in `scripts/autoloads/`
- Direction handling uses `enum Dir { DOWN, UP, LEFT, RIGHT }` with typed `Dictionary[Dir, StringName]` constants (`IDLE_ANIM`, `WALK_ANIM`) and `Dictionary[Dir, Vector2]` for `DIR_VECTORS`
- Animation names as `&"StringName"` literals for compile-time validation
- Group constants in `scripts/groups.gd` (`class_name Groups`) — use `Groups.INTERACTABLE`, `Groups.DIALOGUE_BOX` instead of string literals
- Scene exports (`@export var music: AudioStream`, `@export var default_spawn: Vector2`) over hardcoded paths
- Autoloads accessed by global name directly (`GameState`, `MusicManager`, etc.)
- No `@warning_ignore` — use typed dictionaries, `is` type guards, explicit variable typing, and `call()` for duck-typed methods

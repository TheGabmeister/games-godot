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

**Warning:** `--headless --import` may re-add removed autoloads to `project.godot`. If PartyData reappears in the `[autoload]` section, remove it — PartyData uses `class_name` and is instantiated by WorldSession, not the autoload system.

## Resolution

- **Base viewport:** 1280x720 (stretch mode `viewport`)
- **Tile size:** 64x64 px (20x11 visible tile grid)
- **Character sprites:** 64x96 px (1 tile wide, 1.5 tiles tall)
- **NPC sprites:** 64x96 px (single front-facing idle)

## Architecture

### Autoloads (initialization order)

1. **DialogueData** (`scripts/dialogue_data.gd`) — Loads and caches JSON dialogue files from `data/dialogue/`. Called with `DialogueData.get_dialogue(path, id)`.
2. **MusicManager** (`scripts/autoloads/music_manager.gd`) — Single-track music on "Music" audio bus. `play(stream)` prevents restarting same track. Auto-loops.
3. **SfxManager** (`scripts/autoloads/sfx_manager.gd`) — Pool of 16 AudioStreamPlayers on "SFX" audio bus. `play(stream, volume_db)`.
4. **GameState** (`scripts/autoloads/game_state.gd`) — State machine with enum `State { TITLE, FIELD, DIALOGUE, BATTLE, CUTSCENE, MENU }`. All scripts gate input with `GameState.is_state()`. Transitions via `GameState.transition()`, emits `state_changed(old_state, new_state)` signal.

**PartyData is NOT an autoload.** It has `class_name PartyData` for type references but is instantiated by WorldSession and passed to consumers via properties. See "PartyData access pattern" below.

### WorldSession — persistent game root

`WorldSession` (`scripts/world_session.gd`) is the persistent root scene loaded after the title screen. It owns all elements that survive level transitions:

```
WorldSession (Node)
├── PartyData (instantiated via PartyData.new(), not autoload)
├── Warrior (PlayerMovement from warrior.tscn)
│   └── Camera2D (limits updated per level)
├── DialogueBox (CanvasLayer 10 from dialogue_box.tscn)
├── PartyMenu (CanvasLayer 10 from party_menu.tscn)
├── BattleScene (CanvasLayer 20 from battle_scene.tscn)
└── [Current Level] (swapped on door transitions)
    ├── TileMapLayer
    ├── NPCs
    └── DoorTriggers
```

**Level loading:** `_load_level(scene_path)` frees the old level, instantiates the new one at child index 0 (renders behind player), reads `LevelData.music` and `LevelData.default_spawn`, updates camera limits from the TileMapLayer's `get_used_rect()`, and transitions to FIELD state.

**Door transitions:** `door_trigger.gd` finds the WorldSession via `Groups.WORLD_SESSION` group and calls `transition_to_level(scene_path, spawn_position)`. No `change_scene_to_file` — only the level child is swapped.

### Scene flow

`title_screen.tscn` → (confirm) → `world_session.tscn` → loads `cornelia_town.tscn` ↔ (door trigger) ↔ `cornelia_castle.tscn` / `cornelia_outskirts.tscn`

Battle flow: field movement → step counter triggers encounter → `GameState.transition(BATTLE)` → BattleScene overlay → victory/game over → `GameState.transition(FIELD)` (field music resumes via `_on_battle_ended`). Game Over is the one case that uses `change_scene_to_file` to tear down WorldSession and return to title.

### Key scenes

- **`_scenes/warrior.tscn`** — Player character (`class_name PlayerMovement`, CharacterBody2D, collision layer 2 + AnimatedSprite2D + InteractArea). Script: `player_movement.gd`. Only processes in FIELD state. Owns the encounter step counter — emits `encounter_triggered(formation)` when steps exceed threshold. WorldSession sets `encounter_table` per level.
- **`_scenes/npc.tscn`** — Reusable NPC template (StaticBody2D). Exports: `sprite_texture`, `dialogue_file`, `dialogue_id`. Has `interact()` method called via duck typing.
- **`_scenes/dialogue_box.tscn`** — CanvasLayer (layer 10) with character-by-character text reveal + SFX. `class_name DialogueBox`. Emits `dialogue_finished` signal.
- **`_scenes/door_trigger.tscn`** — Reusable Area2D (collision layer 4, mask 2). Exports: `target_scene_path`, `spawn_position`. Calls `WorldSession.transition_to_level()` on player body enter.
- **`_scenes/party_menu.tscn`** — CanvasLayer (layer 10) with left panel (menu entries, time, gil) and right panel (subscreen panels toggled by visibility). All layout in scene, all styling via `ui/menu_theme.tres` theme resource. Node references use `%` unique names. Single script (`party_menu.gd`) handles all subscreen logic.
- **`_scenes/battle_scene.tscn`** — CanvasLayer (layer 20) overlay for turn-based combat. `class_name BattleScene`. Three-panel bottom HUD (command menu, enemy list, party HP) matching FF1 Pixel Remaster layout (see `docs/ff1/battle_menu.png`). Enum state machine (`BattlePhase`) drives input dispatch via `match _battle_phase` in `_input()`. WorldSession instantiates it and passes `party_data`. Uses `BattleFormulas` for damage/hit/crit calculations and `Battler` inner class as a unified wrapper for both party members and enemies during combat.
- **Level scenes** (`cornelia_town.tscn`, `cornelia_castle.tscn`, `cornelia_outskirts.tscn`) — Use `LevelData` script with `@export var music`, `@export var default_spawn`, and `@export var encounter_table: EncounterTable` (null for towns = no random encounters). Contain only TileMapLayer, NPCs, and door triggers — no player, camera, or UI.

### PartyData access pattern

`PartyData` (`scripts/autoloads/party_data.gd`) has `class_name PartyData` so type references (`PartyData.Job`, `PartyData.CharacterData`) work globally. But it is NOT an autoload — WorldSession creates it and passes it via properties:

```
WorldSession._ready() → PartyData.new() → party_menu.party_data = party_data
                                         → battle_scene.party_data = party_data
```

### Menu system

**PartyMenu** (`scripts/ui/party_menu.gd`, `_scenes/party_menu.tscn`) — single CanvasLayer containing all menu UI. Listens to `GameState.state_changed` — opens when state enters MENU, closes when state leaves MENU. All subscreen layouts (party overview, items, target select, status select/detail, formation, stub) are built into the scene as sibling VBoxContainers under `Screens`; the script toggles visibility via `_switch_panel()`.

**GameButton** (`scripts/ui/game_button.gd`, `_scenes/game_button.tscn`) — reusable Label subclass for selectable menu entries. Manages cursor prefix (`"> "` selected, `"* "` marked, `"  "` default) and gold color override for marked state. Set text via `button_text` property, toggle state via `set_selected(bool)` and `set_marked(bool)`. Used for all selectable items: main menu entries, item list, target/status select, formation list. Dynamic items (e.g., inventory) create instances via `GameButton.new()`.

**CharacterRow** (`scripts/ui/character_row.gd`, `_scenes/character_row.tscn`) — self-contained HBoxContainer for party overview rows. Owns portrait, name, HP, MP, level, and next-level labels. Call `populate(character: PartyData.CharacterData)` to fill all fields. Four instances in the party overview panel.

**Theme** (`ui/menu_theme.tres`) — shared theme resource set on the root Panel. Defines default Label style and type variations: `TitleLabel` (gold, 24px), `ValueLabel` (white, 20px), `AccentLabel` (gold, 20px), `HintLabel` (light blue, 20px), `SmallLabel` (light blue, 18px), `MutedLabel` (muted, 22px). Designers edit the theme in Godot's visual editor to change all menu styling.

**Screen state** uses `enum Screen { MAIN, ITEMS, ITEMS_TARGET, MAGIC, EQUIPMENT, STATUS, STATUS_DETAIL, FORMATION, CONFIG }`. Each screen owns its own cursor variable (`_main_cursor`, `_items_cursor`, `_status_cursor`, `_formation_cursor`) so backing out of a submenu preserves the parent screen's position. Input is dispatched via `match _current_screen` in `_input()`. Cursor movement is handled by a shared `_move_cursor(event, current, size) -> int` helper.

### Battle system

**BattleScene** (`scripts/battle/battle_scene.gd`, `_scenes/battle_scene.tscn`) — CanvasLayer overlay that runs turn-based combat. Internal enum `BattlePhase { INACTIVE, INTRO, COMMAND_SELECT, TARGETING, ITEM_SELECT, ITEM_TARGET, RESOLVING, ANIMATING, VICTORY, GAME_OVER }`. Input dispatch uses `match _battle_phase` in `_input()`, gated by `GameState.is_state(BATTLE)`.

**Battler** (inner class in `battle_scene.gd`) — unified wrapper for party members and enemies during combat. Party Battlers hold a reference to `CharacterData` (HP changes sync back). Enemy Battlers are ephemeral, created from `EnemyData`. Turn order sorts a single `Array[Battler]` by agility.

**BattleFormulas** (`scripts/battle/battle_formulas.gd`) — static functions for damage calculation, hit/crit checks, run chance, formation targeting weights, EXP distribution. All formulas from SPEC.md §1.3.

**Encounter flow:** PlayerMovement counts tile-steps, picks a weighted-random formation from the level's `EncounterTable`, emits `encounter_triggered`. WorldSession receives the signal and calls `BattleScene.start_battle()`. After battle, WorldSession restores field music via `battle_ended` signal.

**Command input:** Index-driven loop (`_command_index` 0-3). Each character picks Attack/Item/Run, then selects a target. After all 4, round resolves. Enemy commands use formation-weighted targeting (50/25/12.5/12.5% by party position).

### Data resources

- **EquipmentData** (`scripts_consts/equipment_data.gd`) — `Slot { WEAPON, SHIELD, BODY, HEAD, ARMS }`, attack_power, absorb, evade_penalty, hit_percent, weapon_index. `.tres` files in `data/equipment/`.
- **EnemyData** (`scripts_consts/enemy_data.gd`) — enemy stats + sprite texture. `.tres` files in `data/enemies/`.
- **EncounterTable** (`scripts_consts/encounter_data.gd`) — battle_background, formations array, can_flee, steps_min/max. Assigned to LevelData via `@export var encounter_table`.
- **EncounterFormation** (`scripts_consts/encounter_formation.gd`) — array of `EnemyEntry` + weight for weighted random selection.
- **EnemyEntry** (`scripts_consts/enemy_entry.gd`) — enemy reference + count.

CharacterData (in `party_data.gd`) has 5 equipment slots, computed combat properties (`get_attack_power()`, `get_absorb()`, `get_evade()`, `get_hit_percent()`, `get_max_hits()`, `get_crit_rate()`), EXP tracking, and deterministic level-up via stat growth tables.

### Interactable system

NPCs (and future interactables) use duck typing via `Groups.INTERACTABLE` (`scripts_consts/groups.gd`). The NPC's `InteractionArea` (Area2D child) is in the `"interactable"` group. The player finds the nearest interactable facing them and calls `target.call(&"interact")`. Each interactable implements its own `interact()` method.

### Input handling pattern

Scripts check `GameState.is_state()` at the top of `_physics_process` and `_input`. Discrete actions use `_input()`, continuous movement uses `_physics_process()`. Consume events with `get_viewport().set_input_as_handled()`. The player transitions FIELD → MENU by calling `GameState.transition(State.MENU)` — PartyMenu reacts via signal, not direct call.

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

Character sprite sheets: 192x384 PNG (3 columns × 4 rows: idle/walk1/walk2 × down/left/right/up). Generator: `scripts/gen_sprites.py`. SVG sources kept alongside PNGs in `characters/<name>/`. SpriteFrames `.tres` files use AtlasTexture regions from the sheet. Battle stance sprites: single 64x96 PNGs (`*_battle.svg` → `*_battle.png`) in the same character folders.

NPC sprites: single 64x96 PNGs in `characters/npcs/`.

Enemy sprites: SVG → PNG in `enemies/`. Sizes vary per enemy (64x64 to 96x96).

### Tiles

Tileset atlas: 512x256 PNG (8×4 grid of 64x64 tiles). Generator: `tilesets/gen_tiles.py`. Tileset resource: `tilesets/cornelia_tileset.tres` with physics polygons on impassable tiles.

### Music

Python scripts generate MIDI via `midiutil`: `music/gen_music.py` (title/town/castle themes), `music/gen_battle_music.py` (battle/victory/game over). Render pipeline: Python → MIDI → fluidsynth (with 8bitsf.SF2) → WAV → ffmpeg (with trailing silence trim) → OGG. Only the `.py` and `.ogg` files are kept; `.mid` and `.wav` are intermediates.

### SFX

Generated via ffmpeg synthesis filters (`sine`, `anoisesrc`, `aevalsrc`). Menu SFX in `ui/`, battle SFX in `sfx/`. No generator script — created via one-off commands.

### Dialogue

JSON files in `data/dialogue/` (one per area). Structure: `{ "id": { "name": "NPC Name", "lines": ["..."] } }`. NPCs reference these via `dialogue_file` and `dialogue_id` exports.

## Conventions

- Scenes in `_scenes/` (underscore prefix for editor sorting)
- Autoloads in `scripts/autoloads/`
- UI scripts in `scripts/ui/`
- Battle scripts in `scripts/battle/`
- Stateless constants and resource classes in `scripts_consts/` (`Groups`, `ItemData`, `LevelData`, `EnemyData`, `EquipmentData`, `EncounterTable`, etc.)
- Data resources (`.tres`) in `data/` subdirectories (`items/`, `equipment/`, `enemies/`, `encounters/`)
- Direction handling uses `enum Dir { DOWN, UP, LEFT, RIGHT }` with typed `Dictionary[Dir, StringName]` constants (`IDLE_ANIM`, `WALK_ANIM`) and `Dictionary[Dir, Vector2]` for `DIR_VECTORS`
- Animation names as `&"StringName"` literals for compile-time validation
- Group constants in `scripts_consts/groups.gd` (`class_name Groups`) — use `Groups.INTERACTABLE`, `Groups.PARTY_MENU`, etc. instead of string literals
- Scene exports (`@export var music: AudioStream`, `@export var default_spawn: Vector2`) over hardcoded paths
- Autoloads accessed by global name directly (`GameState`, `MusicManager`, etc.)
- No `@warning_ignore` — use typed dictionaries, `is` type guards, explicit variable typing, and `call()` for duck-typed methods. Capture discarded return values with `var _x :=` (tween chains, `connect()`, `resize()`, etc.)
- UI scenes use `%` unique names (`unique_name_in_owner = true`) for all script-referenced nodes — reference via `%NodeName` in GDScript, not `$Path/To/Node`. Duplicated structures (e.g., 4 character rows) use indexed unique names (`CharName0`, `CharName1`, etc.)

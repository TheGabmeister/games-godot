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

### Gameplay scene wrapper

`scenes/gameplay.tscn` is the main scene. It wraps the current level and owns all gameplay-scoped systems. Systems that only exist during gameplay (not title screen or credits) live here instead of as autoloads.

```
Gameplay (Node, gameplay.gd)
├── PartyManager      — runtime party state (HP, KO), persists across battles
├── BattleManager     — combat loop orchestrator
├── Inventory         — item tracking
├── BattleUI          — battle HUD + menus (CanvasLayer)
├── DialogueBox       — typewriter dialogue (CanvasLayer)
└── Level             — instance of the current level scene (e.g., debug_room.tscn)
    ├── Player, Marle, Lucca
    ├── Enemies
    ├── NPC, Camera
    └── Walls
```

`gameplay.gd` initializes PartyManager with the party nodes from the Level in `_ready()`.

### Autoloads

**GameState** (scripts/game_state.gd) — central state machine. All input-handling scripts gate on `GameState.current`.

```
enum State { FIELD, DIALOGUE, BATTLE }  — expanded each phase (MENU, CUTSCENE...)
```

State transitions go through `GameState.change(new_state)` which emits `state_changed`.

**MusicManager** (scripts/music_manager.gd) — owns an AudioStreamPlayer. `play_music(stream, volume_db)` and `stop_music()`. Loops by re-playing on `_on_player_finished()` signal.

### Group-based lookups

Scripts find gameplay systems via groups instead of hard-coded paths. Group name constants live in `scripts/groups.gd` (class_name `Groups`) to avoid magic strings:

```gdscript
Groups.PARTY_MANAGER   Groups.BATTLE_MANAGER
Groups.INVENTORY        Groups.DIALOGUE_BOX
```

Systems register in `_ready()` with `add_to_group(Groups.XXX)`. Scripts find them via `get_tree().get_first_node_in_group(Groups.XXX)`. Enemies also use dynamic groups (`"enemy_" + encounter_group`) for encounter grouping.

### Input map

| Action         | Keys            | Gamepad            |
|----------------|-----------------|--------------------|
| `move_up`      | W / Up arrow    | D-pad up / stick   |
| `move_down`    | S / Down arrow  | D-pad down / stick |
| `move_left`    | A / Left arrow  | D-pad left / stick |
| `move_right`   | D / Right arrow | D-pad right / stick|
| `interact`     | Z / Enter       | A (bottom face)    |
| `cancel`       | X               | B (right face)     |
| `escape_left`  | Q               | LB                 |
| `escape_right` | E               | RB                 |

### Interaction pattern

Player has a RayCast2D (`InteractRay`, 20px) pointing in the facing direction. On interact press, if the ray hits a node in the `"interactable"` group, it calls `collider.interact()`. NPCs add themselves to this group in `_ready()` and implement `interact()`.

### Party system

**PartyManager** owns runtime state for each party member: `{ "data": CharacterData, "current_hp": int, "is_ko": bool, "node": Node2D }`. HP and KO status persist across battles. BattleManager reads the roster on battle start and writes back on victory.

**Party members** use two scripts:
- `player.gd` — the leader (Crono). Handles movement, records position history for followers.
- `party_follower.gd` — followers (Marle, Lucca). Replays the leader's position history with a configurable frame delay (snake formation).

Both expose the same battle animation interface: `play_attack()`, `play_idle()`, `play_hit(direction)`.

### Battle system

**Data flow:**
```
CharacterData/EnemyData (.tres)  →  PartyManager (persists HP/KO)
                                          │
                                          ▼ copies on battle start
                                    BattleManager (ATB, combat HP, turn queue)
                                          │ emits signals
                                          ▼
                                    BattleUI (updates HUD)
                                    Party member nodes (play animations)
```

**Multi-actor ATB**: Every combatant (3 party + N enemies) has an ATB gauge filling at `speed * delta * ATB_SCALE` (0.02). Party members fill into a ready queue (FIFO). The first ready member gets the command menu; enemies auto-attack a random living party member.

**Wait/Active mode**: In Wait mode, non-acting gauges pause during submenus (item list, target selection). Top-level command menu does not pause gauges.

**Encounter groups**: Enemies with matching `encounter_group` exports fight together. Walking into any enemy in a group triggers battle with all of them.

**Escape**: Hold `escape_left` + `escape_right` to fill an escape gauge. Boss-flagged encounters block escape.

**BattleManager signals** (battle_ui connects to these):
`battle_started`, `battle_ended`, `atb_updated`, `command_ready_changed`, `party_hp_changed`, `enemy_hp_changed`, `damage_dealt`, `heal_applied`, `victory_achieved`, `player_defeated`, `enemy_died`, `combatant_ko`, `active_member_changed`, `submenu_entered`, `submenu_exited`, `escaped`

**BattleUI menu states**: `HIDDEN → COMMAND → TARGET_ENEMY` (for Attack) or `COMMAND → ITEM_LIST → TARGET_ALLY` (for Item). Cancel returns to the previous state.

**Attack animation sequence**: pause gauges → attacker plays attack anim + lunges 16px (0.15s) → target plays hit + FlashEffect + floating damage number (0.3s) → attacker retreats (0.15s) → resume.

**Damage formula**: `raw = max(1, power + weapon_ap - target_stamina)`, randomized ×0.9–1.1, doubled on crit (checked against `strike_percent`).

### Resources as data

Game data is authored as Godot Resource `.tres` files:
- `CharacterData` — name, max_hp, power, speed, stamina, strike_percent, weapon_ap (party/)
- `EnemyData` — name, stats, rewards (enemies/)
- `ItemData` — name, heal_amount, target_type (items/)
- `DialogueData` — speaker name + lines array (dialogue/)

Pattern: entity nodes hold `@export var data: ResourceClass`. Runtime state is copied from the resource at battle start, keeping the resource immutable.

### Folder structure

```
res://
├── dialogue/    — DialogueData .tres files
├── enemies/     — EnemyData .tres files + enemy sprites
├── items/       — ItemData .tres files
├── npc/         — NPC sprites and audio
├── party/       — CharacterData .tres + party member sprites
├── player/      — Player (Crono) sprites and audio
├── props/       — Environment/tilemap sprites and audio
├── scenes/      — All .tscn scene files
├── scripts/     — All .gd script files
├── tools/       — Asset export scripts
└── docs/        — Spec companion files + completed phase specs (docs/impl/)
```

Sprites and audio live alongside their entity. Scripts and scenes are centralized in their own folders.

## Implementation Status

Phases 1–3 are complete. Phases 4–10 are spec-only (see IMPL_XX.md files).

- **Phase 1**: Player movement, NPC interaction, dialogue typewriter, camera follow
- **Phase 2**: 1v1 ATB battle, damage formula, battle animations, battle music, victory/game over
- **Phase 3**: 3-member party, multi-enemy encounters, ATB ready queue, Attack/Item commands, target selection, escape mechanic, Wait/Active mode, Inventory, snake formation followers, gameplay scene wrapper

Completed phase specs live in `docs/impl/`. The active phase spec (`IMPL_03.md`) is at the project root.

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

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Godot 4.6 recreation of Zelda: A Link to the Past mechanics using primitive shapes (no sprites). GDScript only. The game is 2D at 256x224 logical resolution on a 16x16 tile grid, rendered with Forward Plus.

No original Nintendo sprites, tiles, or audio assets. All visuals use `_draw()`, `Polygon2D`, shaders, particles, and `PointLight2D`.

## Key Files

- **SPEC.md** — primary source of truth. Read the relevant section before making changes.
- **AGENTS.md** — architecture guardrails and non-negotiable rules.
- **project.godot** — engine configuration (4.6, Forward Plus, d3d12).

If implementation pressure conflicts with the spec, favor the spec and document any deliberate deviation.

## Running the Project

```bash
# Godot executable — use full path (no bash alias configured)
"d:/Godot_v4.6.2-stable_win64.exe" --path .                                    # Open editor
"d:/Godot_v4.6.2-stable_win64.exe" --path . --scene res://scenes/main/main.tscn  # Run main scene
"d:/Godot_v4.6.2-stable_win64.exe" --path . --headless --quit                    # Headless smoke check
"d:/Godot_v4.6.2-stable_win64.exe" --path . --headless --import                  # Reimport (needed after adding new class_name scripts)

# GUT unit tests (after GUT is installed in Phase 2)
"d:/Godot_v4.6.2-stable_win64.exe" --path . --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit
```

**Important:** After creating new scripts with `class_name`, run `--headless --import` before `--headless --quit` or the class_name types won't be in the cache and scripts will fail to parse.

## Testing

Every subphase in SPEC.md has a **Verification** block with concrete checks. A subphase is not done until its Verification passes.

Three verification types:
1. **Unit tests** — GUT framework (`res://tests/unit/`) for pure logic: damage formula, `PlayerState` acquisition, loot tables, save serialization.
2. **Debug scene checks** — load `debug/debug_room.tscn` or a dedicated `tests/scenes/*.tscn` and verify behavior manually.
3. **Headless smoke checks** — `godot --path . --headless --quit` after any change.

## Architecture

The project follows a phase-based implementation plan (SPEC.md Phases 1-9). Each phase produces a playable build. If the repo doesn't yet support a feature's prerequisite phase, implement the prerequisite first or note the forward scaffolding.

**Scene tree at runtime:**
```
Main (Node)
  +-- World (Node2D)              -- SceneManager swaps room scenes here
  +-- HUDLayer (CanvasLayer 10)
  +-- DialogLayer (CanvasLayer 15)
  +-- PostProcessLayer (CanvasLayer 19) -- bloom/color-grade shader
  +-- TransitionOverlay (CanvasLayer 20)
  +-- PauseLayer (CanvasLayer 25, process_mode=ALWAYS)
```

**Autoload order matters:** EventBus -> GameManager -> ItemRegistry -> PlayerState -> AudioManager -> SceneManager -> SaveManager -> Cutscene (Phase 6+)

### Ownership Split: SceneManager vs GameManager

**SceneManager** owns all transient navigation state:
- `current_room`, `current_room_data: RoomData`, `current_screen_coords`
- `room_registry: Dictionary[StringName, String]` (room_id -> scene_path, built from RoomData scans at startup)

**GameManager** owns persistent run-level state only:
- Global flags dictionary, pause state, last_safe_room_id, last_safe_position, current save slot
- Does NOT track current room/dungeon/world -- reads from `SceneManager.current_room_data` when needed

Other autoloads (PlayerState, SaveManager) read `SceneManager.current_room_data` for dungeon_id, world_type, room_id.

### Room System

Every room must have a `RoomData` resource (`@export var room_data: RoomData` on `room.gd`). RoomData is the single source of truth for room metadata (room_id, scene_path, dungeon_id, world_type, music, neighbors). Rooms without a RoomData are undiscoverable by transitions. The room script's `dungeon_id` is a read-only property delegating to `room_data.dungeon_id` -- no separate export.

All transitions use `room_id` StringNames, never raw scene paths. SceneManager resolves ids via its registry.

### Player and State Machines

**Player is persistent** -- created once per run, reparented into each room's `Entities` node during transitions. Never duplicated or recreated.

**State machines** are generic (`components/state_machine.gd`). Player, enemies, and bosses all use the same StateMachine node with type-specific State subclasses. **Watch the naming collision**: `BasePlayerState` is the state-machine base class; `PlayerState` is the autoload holding the character sheet. They are unrelated.

### Enemy and Boss Systems

**Enemies use composition, not scene inheritance.** No `base_enemy.tscn`. Each enemy is a standalone scene using `base_enemy.gd` as its script base class. States are per-enemy-type (only `StunnedState` is shared).

**Bosses are NOT enemies.** `base_boss.gd` extends `Node2D` (not `CharacterBody2D`). Each boss is a bespoke scene with its own state machine and sub-entities.

### Item Acquisition Pipeline

Items are not an inventory. Three categories only: **SKILL** (equippable ability), **UPGRADE** (monotonic stat tier), **RESOURCE** (countable consumable). `PlayerState.acquire(item)` is the single entry point.

The RESOURCE path has special routing for dungeon-scoped items:
- `big_key`/`map`/`compass` -> `GameManager.set_flag()` using `SceneManager.current_room_data.dungeon_id`
- `small_key` -> `PlayerState.add_small_key()` with dungeon_id from SceneManager
- All others -> increment PlayerState counters directly

Upgrade acquisition is monotonic (`max(current, tier)`). Gameplay-driven downgrades (Like-Like) use the separate `reduce_upgrade()` method.

Only SKILL items persist as `ItemData` references. UPGRADE and RESOURCE items are consumed at acquisition.

### Persistence

`@export var persist_id: StringName` on entities, `room_id` from `RoomData`. Flag keys: `{room_id}/{persist_id}`. Never derive IDs from node names or scene paths. Treat room IDs, item IDs, and flag keys as save-migration-sensitive.

## Physics Layer Bitmask Reference

Godot uses 1-indexed layers but 0-indexed bitmask values in `.tscn` files:

| Layer | Name | Bitmask Value |
|-------|------|---------------|
| 1 | World | 1 |
| 2 | Player | 2 |
| 3 | Enemies | 4 |
| 4 | PlayerAttacks | 8 |
| 5 | EnemyAttacks | 16 |
| 6 | Interactables | 32 |
| 7 | Hazards | 64 |
| 8 | Triggers | 128 |

Combine with bitwise OR. Example: EnemyAttacks + Hazards = 16 + 64 = 80.

## Conventions

- Health unit = half heart. Starting health = 6 (3 hearts). Magic = 0-128 units (fixed max).
- Rooms use `y_sort_enabled = true` on the `Entities` node.
- JSON saves use basic types only. Convert `Vector2` to `[x, y]` arrays. Include `schema_version`.
- Enemies respawn on room re-entry. Chests/blocks/switches persist via GameManager flags.
- Audio: drop files at `res://audio/bgm/{name}.ogg` or `res://audio/sfx/{name}.ogg`. System logs when assets are missing.
- Cutscene lifecycle signals live on the `Cutscene` autoload (not EventBus).
- `ItemRegistry` lookup by stable id; never hardcode `.tres` paths in gameplay code.
- In `.tscn` files, `sub_resource` definitions must appear before any node that references them (order matters).
- `BasePlayerState.player` is typed as `CharacterBody2D`, not `Player`. Use explicit type annotations (e.g., `var x: Vector2 = player.facing_direction`) instead of `:=` inference when accessing `Player`-specific properties to avoid parse errors.

### Combat Components (Phase 2.1)

`components/` contains reusable combat building blocks:
- **HitboxComponent** (`Area2D`) — deals damage. Exports: damage, damage_type, knockback_force, effect (HitEffect), source_team. Provides `get_hitbox_data()` dict.
- **HurtboxComponent** (`Area2D`) — receives hits. Tracks i-frames. Emits `hurt(hitbox_data)`. Environmental damage types (PIT, WATER, SPIKE) bypass i-frames.
- **HealthComponent** — enemy health tracking. `take_damage()`, `heal()`, signals `health_changed`/`died`.
- **KnockbackComponent** — decelerating knockback. `apply(direction, force, duration)`.
- **FlashComponent** — white flash via `damage_flash.gdshader`. Auto-finds `*Body*` visual node.
- **DamageFormula** — static `calculate_damage()` implementing the 4-step pipeline (shield, immunity, armor reduction, minimum 1).

The player does NOT use HealthComponent — player health lives on `PlayerState` autoload since it's persistent and serialized. Enemies use HealthComponent since they're transient per room.

## Current Phase Status

Phase 1 complete, Phase 2.1 (combat components) complete. The repo has: project config, all 7 autoloads, generic state machine, player with 6 states (Idle/Walk/Attack/Knockback/Fall/Dash), room system with debug room, HUD (hearts/rupees/item slot), camera with room bounds and screen shake, 6 shaders, shared resources (ItemData/RoomData/EnemyData/LootTable/DungeonData/DamageType), and combat components (HitboxComponent/HurtboxComponent/HealthComponent/KnockbackComponent/FlashComponent/DamageFormula).

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
- **HurtboxComponent** (`Area2D`) — receives hits. Tracks i-frames. Emits `hurt(hitbox_data)`. Environmental damage types (PIT, WATER, SPIKE) bypass i-frames. Also handles meta-based areas (like SwordHitbox) via `has_meta("damage")` path with `source_team` team check.
- **HealthComponent** — enemy health tracking. `take_damage()`, `heal()`, signals `health_changed`/`died`.
- **KnockbackComponent** — decelerating knockback. `apply(direction, force, duration)`.
- **FlashComponent** — white flash via `damage_flash.gdshader`. Auto-finds `*Body*` visual node.
- **DamageFormula** — static `calculate_damage()` implementing the 4-step pipeline (shield, immunity, armor reduction, minimum 1).
- **LootDropComponent** — `@export var drop_table: LootTable` for direct use on any object; falls back to `parent.enemy_data.drop_table` for enemies. Spawns Pickup scenes on death/destruction.

The player does NOT use HealthComponent — player health lives on `PlayerState` autoload since it's persistent and serialized. Enemies use HealthComponent since they're transient per room.

### Enemy Architecture (Phase 2.3)

`base_enemy.gd` (class_name `BaseEnemy`) extends `CharacterBody2D`. Shared logic: damage reception via `DamageFormula` + `EnemyData.damage_immunities`, knockback with resistance, death sequence (CPUParticles2D + loot + `EventBus.enemy_defeated` + `queue_free()`).

`BaseEnemyState` extends `State`, types `actor` as `BaseEnemy`. Shared `StunnedState` (`scenes/enemies/shared/stunned_state.gd`): immobile, blue tint, timer, returns to prior state.

Enemy collision setup:
- Root `CharacterBody2D`: layer=Enemies(4), mask=World(1)
- `HurtboxComponent`: layer=Enemies(4), mask=PlayerAttacks(8)
- `ContactHitbox` (HitboxComponent): layer=EnemyAttacks(16), mask=0, monitoring=false, monitorable=true

Player's `SwordHitbox`: layer=PlayerAttacks(8), monitorable=true. Sets `source_team` meta so `HurtboxComponent` team check works via the meta path.

### Projectile System (Phase 2.6)

`Projectile` (`scenes/projectiles/projectile_base.gd`) extends `Area2D`. Properties: speed, damage, damage_type, direction, lifetime, pierce, deflectable, source_team. Auto-configures collision layers by team (enemy: layer=EnemyAttacks, mask=World+Player; player: layer=PlayerAttacks, mask=World+Enemies). Destroys on wall collision (`body_entered`) and on opposing hurtbox contact (`area_entered`, unless `pierce`). Sets hitbox metadata for `HurtboxComponent` detection via the meta path.

### Loot and Pickup System (Phase 2.7)

`LootTable` uses `PackedStringArray` item_ids resolved via `ItemRegistry` at roll time — not Resource array references. Supports `quantity_min`/`quantity_max` per entry. `roll()` returns `Array[ItemData]` (zero or more). `Pickup` scene (`scenes/pickups/pickup.gd`): bobs, magnetizes toward player within 16px, collects within 8px, despawns after 10s. Calls `PlayerState.acquire()` on collection. 9 RESOURCE ItemData .tres files in `resources/items/pickups/`.

### Item Use System (Phase 3.4)

`BaseItemEffect` extends `RefCounted`. Virtual methods: `can_use(player) -> bool`, `activate(player) -> float` (returns lock duration for ItemUseState). Each skill has an effect script in `scenes/items/effects/`. `PlayerState` instantiates and caches effects on acquisition.

`ItemUseState`: checks `can_use()`, calls `consume_skill_cost()`, then `activate()`. Lock timer returns to Idle. Hookshot overrides via direct `transition_to("Idle")` when done.

Spawned item scenes in `scenes/items/`: `arrow.tscn` (extends Projectile), `bomb.tscn` (fuse timer + explosion Area2D), `boomerang.tscn` (outbound + return + stun + pickup collection), `hookshot.tscn` (raycast + extend/retract).

### Shield Mechanics (Phase 3.7)

`ShieldComponent` (`components/shield_component.gd`) extends `Area2D`. Reads shield tier from `PlayerState.get_upgrade("shield")`. Tier 1 blocks rocks/arrows, Tier 2 adds fireballs/beams, Tier 3 adds magic + reflects. Checks `projectile_class` metadata or infers from `damage_type`. Facing check uses dot product with configurable threshold (wider when `action_shield` held).

### Pause Subscreen (Phase 3.8)

`PauseSubscreen` (`scenes/ui/pause_subscreen.gd`) on `PauseLayer` (CanvasLayer 25, process_mode=ALWAYS). Opens/closes via `pause` input in `main.gd`. Skill grid with cursor navigation, equipped skill display, upgrade pip displays, resource status. Selecting a skill equips it to the B button.

### Chest System

`Chest` (`scenes/objects/chest.gd`) extends `StaticBody2D`. `@export var item: ItemData`, `@export var persist_id: StringName`. On interact: emits `EventBus.item_get_requested(item)`, sets persist flag via `GameManager`. Player `InteractionProbe` (Area2D, mask=Interactables) detects chests; `try_interact()` called from Idle/Walk states on `interact` input.

### Transition System (Phase 4)

`TransitionOverlay` (`scenes/main/transition_overlay.gd`) on CanvasLayer 20. Provides `fade_out()`, `fade_in()`, `iris_out(center)`, `iris_in(center)`, `instant_black()`, `clear()`. Uses `screen_transition.gdshader` for iris effect. All methods are awaitable.

### Room Transitions (Phase 4.1-4.2)

Screen-edge scroll transitions for overworld: player walks past screen boundary, `SceneManager.scroll_to_room()` loads adjacent room, tweens both rooms + player over 0.5s, then frees old room. `RoomData.neighbor_ids` maps directions to room_ids.

`Door` (`scenes/objects/door.gd`) extends `Area2D`. Walk-in or interact trigger. Exports: `target_room_id`, `target_entry_point`, `transition_style` (fade/iris/instant). Emits `EventBus.room_transition_requested`.

`SceneManager.load_room_with_transition()` handles fade/iris/instant styles with the TransitionOverlay.

### Dungeon Elements (Phase 4.3)

- **LockedDoor** (`scenes/objects/locked_door.gd`) — barrier that consumes one small key scoped to dungeon_id from parent Room. Becomes passable on unlock. Persists via GameManager flag. Not a teleporter — place a Door trigger behind it for room transitions.
- **BossDoor** (`scenes/objects/boss_door.gd`) — barrier that gates on big key (`GameManager.get_flag("{dungeon_id}/has_big_key")`). Does not consume the key. Same pattern as LockedDoor: barrier only, pair with a Door for transitions.
- **PushBlock** (`scenes/objects/push_block.gd`) — pushes 1 tile in facing direction. Persists position. Checks pressure plates after push.
- **DungeonSwitch** (`scenes/objects/switch.gd`) — sword-activated toggle. Links to SwitchDoor nodes.
- **PressurePlate** (`scenes/objects/pressure_plate.gd`) — activates with player/block weight. Optional sticky mode.
- **SwitchDoor** (`scenes/objects/switch_door.gd`) — barrier controlled by Switch or PressurePlate via `set_switch_state()`.
- **ConveyorBelt** (`scenes/objects/conveyor_belt.gd`) — continuous directional push on CharacterBody2D entities.

### Light/Dark World (Phase 4.4)

`WorldPortal` (`scenes/objects/world_portal.gd`) — walk-in trigger that emits `EventBus.world_switch_requested`. `SceneManager.switch_world()` finds mirrored room by data-driven RoomData lookup (cached at startup), fades, loads, preserves player position. Without Moon Pearl upgrade, player `is_bunny = true` (pink bunny form, limited actions). Magic Mirror skill returns to Light World from Dark World.

### Dungeon Completion (Phase 5.1)

`RewardPedestal` (`scenes/rooms/components/reward_pedestal.gd`) — Phase 5 placeholder for dungeon completion (Phase 9 replaces with real boss). On interact: sets reward flag + dungeon completion flag, fully heals player, presents reward via `ItemGetState`, then spawns a `WarpTile` back to dungeon entrance. Persists via GameManager flag so it doesn't retrigger.

`WarpTile` (`scenes/rooms/components/warp_tile.gd`) — glowing floor trigger that emits `room_transition_requested` on player contact to return to dungeon entrance.

## Current Phase Status

Phase 1 complete, Phase 2 complete (2.1-2.7), Phase 3 complete (3.1-3.8), Phase 4 complete (4.1-4.4), Phase 5 complete (5.1). All 5 enemy types implemented with full behavior. Projectile system, pickup/loot system with 13 pickup types (9 original + small_key, big_key, map, compass), weighted loot tables wired to all enemies. Phase 3: 10 SKILL items (Bow, Bomb, Boomerang, Hookshot, Lamp, Fire Rod, Ice Rod, Hammer, Magic Powder, Magic Mirror) with effect scripts. 16 UPGRADE items. Phase 4: 4x4 light world overworld grid with screen-edge scroll transitions, 2 interiors (cave + house) with iris/fade transitions, 4-room dungeon (Eastern Palace) with locked door, boss door, push block, switch, pressure plate, and chests. 2x2 dark world subset with world portal and bunny transform. TransitionOverlay with fade and iris effects. Door, LockedDoor, BossDoor, PushBlock, DungeonSwitch, PressurePlate, SwitchDoor, ConveyorBelt, WorldPortal scene components. Phase 5: Eastern Palace playable end-to-end with RewardPedestal (Pendant of Courage), WarpTile, enemies in all 4 dungeon rooms. Three test scenes: `debug/damage_formula_test.tscn` (38 tests), `debug/test_loot_table.tscn` (10 tests), `debug/test_player_state.tscn` (37 tests).

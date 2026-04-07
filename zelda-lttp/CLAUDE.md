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

**Autoload order matters:** EventBus -> GameManager -> ItemRegistry -> PlayerState -> AudioManager -> SceneManager -> SaveManager -> Cutscene

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

### HUD Polish (Phase 6.1)

Hearts flash white briefly when lost. Rupee counter ticks up/down digit by digit. Equipped item slot flashes on skill switch. Semi-transparent dark background panels behind hearts/rupees and item slot for readability.

### Dialog System (Phase 6.2)

`DialogBox` (`scenes/ui/dialog_box.gd`) on DialogLayer (CanvasLayer 15, process_mode=ALWAYS). Typewriter effect at 30 chars/sec. `interact` fast-forwards or advances page. Multi-page arrays. Page-complete indicator triangle when more pages remain.

**Dialog pauses the game.** When dialog opens and the tree isn't already paused (e.g., by ItemGetState), dialog_box pauses it. On close, it only unpauses if it was the one that paused — tracked via `_paused_by_dialog` flag.

**`dialog_closed` ownership is strict.** Only `dialog_box._close_dialog()` emits `EventBus.dialog_closed`. No other system should emit it. `ItemGetState` awaits this signal via `CONNECT_ONE_SHOT` instead of emitting its own. `EventBus.dialog_force_close` exists for programmatic close (e.g., auto-dismiss timers) — dialog_box listens and calls `_close_dialog()`, which then emits `dialog_closed` through the single path.

### Cutscene System (Phase 6.3)

`Cutscene` autoload (`autoloads/cutscene.gd`, process_mode=ALWAYS). Coroutine-based with awaitable primitives: `wait()`, `move_entity()`, `camera_pan()`, `camera_follow()`, `camera_shake()`, `dialog()`, `sfx()`, `fade_to_black()`, `fade_from_black()`, `flash()`. Signals: `cutscene_started`, `cutscene_finished`. Player enters `CutsceneState` on start (input blocked), returns to `IdleState` on finish. Example cutscene: `scenes/cutscenes/sahasrahla_intro.gd`. process_mode=ALWAYS is required because `dialog()` pauses the tree — the coroutine must survive the pause to resume after dialog closes.

### Effects & Juice (Phase 6.4)

- `TorchFlicker` (`components/torch_flicker.gd`) — PointLight2D with organic energy oscillation for dungeon torches.
- `SquashStretch` (`components/squash_stretch.gd`) — reusable scale animation helper. Wired to player Attack (squash→stretch→reset) and Dash (horizontal stretch).
- `ImpactParticles` (`components/impact_particles.gd`) — static methods for one-shot CPUParticles2D bursts: `sword_hit`, `enemy_death`, `bomb_explosion`, `water_splash`, `chest_sparkle`.
- Color grading presets in SceneManager — smooth 0.3s tween of post-process shader uniforms (color_shift, saturation, brightness, contrast) per room's `color_grading_preset`.
- `RoomData.color_grading_preset` field added (default `&"overworld"`).

### Title Screen (Phase 6.5)

`TitleScreen` (`scenes/ui/title_screen.gd` + `.tscn`) — boots on launch. Animated background with scrolling lines and pulsing triforce. Menu: New Game, Continue (grayed when no saves), Options (placeholder), Debug Room (loads `debug_room.tscn` for testing). Slot select screen: 3 slots showing play time, hearts, timestamp. Overwrite confirmation for New Game on occupied slots. Continue skips empty slots and supports delete via B button. Emits `new_game_requested(slot)` / `continue_requested(slot)` / `debug_room_requested` to main.gd.

### Save and Load (Phase 6.6)

`SaveManager` (`autoloads/save_manager.gd`) — fully functional. 3 slots at `user://saves/save_{slot}.json`. `schema_version` for future migration. Methods: `save_game(slot)`, `load_game(slot)`, `has_save(slot)`, `get_slot_metadata(slot)`, `delete_save(slot)`. Serializes `PlayerState` (skills by id via ItemRegistry, upgrades, resources, bottles) and `GameManager` (flags, safe position) under the `game_manager` top-level key. `PlayerState.serialize()`/`deserialize()`/`reset()` and `GameManager.serialize()`/`deserialize()`/`reset()` implemented. Unknown skill ids on load log a warning and are skipped (soft-fail). Play time tracked in main.gd. Save trigger: B button (K/Z) in the pause subscreen.

### Destructible Objects and Lifting (Phase 7.4)

`Destructible` (`scenes/objects/destructible.gd`) base class extends `StaticBody2D`. Weight system: `@export var weight: int` (0=bare hands, 1=Power Glove, 2=Titan's Mitt). Boolean exports: `liftable`, `sword_destroyable`, `dash_destroyable`. Persist via GameManager flags.

Concrete types: `Bush` (sword/dash/throw destroyable, weight 0), `Pot` (lift only, weight 0), `Skull` (lift/throw, weight 0), `SignPost` (shows dialog first, then lifts, weight 0). Each has `_draw()` visuals and a `LootTable` export.

Player states: `LiftState` → `CarryState` → `ThrowState`. Lift triggered by `EventBus.lift_requested` from destructible `interact()`. CarryState: reduced speed, no sword. ThrowState spawns `ThrownObject` (Area2D projectile, shatters on impact, drops loot). `CarriedVisual` node drawn above player head.

`DashState` checks `get_slide_collision()` for `Destructible.dash_destroyable` to break bushes on dash.

### NPC System (Phase 7.3)

`NPC` (`scenes/objects/npc.gd`) extends `Node2D`. Exports: `npc_name`, `dialog_lines`, `required_flag` (invisible until flag true), `reward_item`+`reward_flag` (one-time reward after dialog), `wander_enabled`+`wander_radius`, `npc_color`. Simple humanoid `_draw()` visual. Creates interaction area (Interactables layer) and collision body. Wander uses IDLE/WALKING state with random targets within radius.

### Heart Pieces (Phase 7.2)

`heart_piece.tres` (RESOURCE, resource_key=&"heart_piece") — existing PlayerState logic: 4 pieces = +2 max_health. `heart_container.tres` (RESOURCE, resource_key=&"heart_container") — direct +2 max_health and full heal. 20 heart pieces placed across overworld (13 in chests, 3 in optional caves, 4 as NPC/overworld rewards). 2 heart containers from D02/D03 pedestals. Total achievable max_health = 20 (10 hearts).

### Additional Dungeons (Phase 7.1)

**Dungeon 2: Desert Temple** (`scenes/rooms/dungeons/dungeon_02/`, dungeon_id=&"dungeon_02") — 8 rooms in 2x4 grid. Conveyor/pit-heavy. Entrance→Conveyor Hall→Pit Maze→Key Hub→Conveyor Puzzle→Big Key Room→Pre-Boss→Boss Room. 3 small keys, map, compass, big key. RewardPedestal grants heart_container + sets pendants/power flag.

**Dungeon 3: Shadow Crypt** (`scenes/rooms/dungeons/dungeon_03/`, dungeon_id=&"dungeon_03") — 8 rooms in 3x3 grid (8 used). Dark rooms requiring Lamp (4 of 8 rooms). Traversal puzzles. RewardPedestal grants heart_container + sets pendants/wisdom flag.

Dark room system: `dungeon_room.gd._ready()` sets CanvasModulate to near-black when `room_data.is_dark_room`. `EventBus.room_lit` signal + handler tweens back to normal. `lamp_effect.gd` emits `room_lit` when used in dark room, sets `{room_id}/lit` flag.

### Expanded Overworld (Phase 7.5)

8x8 overworld grid (64 rooms total, expanded from 4x4). 7 biomes: Plains, Forest, Mountain, Lake, Desert, Village, Graveyard, Field. Each biome has unique palette in `overworld_room.gd BIOME_COLORS` and decoration draw functions. Color grading presets added to SceneManager for all biomes.

3 optional caves (`cave_02` through `cave_04`) with heart piece rewards. Dungeon entrances at overworld_6_3 (D02) and overworld_3_5 (D03). NPCs in village biome. Bushes, pots, signs scattered in various rooms.

### Glove Upgrades (Phase 8.1)

`SkullRock` (weight 1, requires Power Glove) and `DarkBoulder` (weight 2, requires Titan's Mitt) extend `Destructible`. LiftState checks `object.weight <= PlayerState.get_upgrade(&"gloves")` with screen shake on fail. Placed in mountain/graveyard overworld rooms as future-gated obstacles. Upgrade items `power_glove.tres` (tier 1) and `titans_mitt.tres` (tier 2) already existed from Phase 3.

### Game Over (Phase 8.2)

`DeathState` (`scenes/player/states/death_state.gd`, process_mode=ALWAYS): spin animation → collapse → emits `EventBus.game_over_requested`. `GameOverScreen` (`scenes/ui/game_over_screen.gd`) on GameOverLayer (CanvasLayer 22, process_mode=ALWAYS): shows Continue / Save and Quit menu. `main.gd` handles:
- `game_over_requested` → pause tree, show screen
- `game_over_continue` → respawn at `GameManager.last_safe_room_id` with 3 hearts (6 half-hearts)
- `game_over_save_quit` → save to current slot, return to title screen

`EventBus.player_died` triggers `player.gd._on_player_died()` → transitions to DeathState.

### Advanced Enemies (Phase 8.3)

**Wizzrobe** (`scenes/enemies/wizzrobe/`): 6 states (Hidden→Appear→Telegraph→Fire→Disappear→repeat + Stunned). No DetectionZone. Teleports to predefined positions. Invulnerable during Hidden/Disappear. Spawns magic Projectile (damage_type=MAGIC, deflectable). `set_invulnerable()` toggles HurtboxComponent collision.

**Like-Like** (`scenes/enemies/like_like/`): 4 states (Idle→Pursue→Engulf + Stunned). DetectionZone for player tracking. On Engulf: forces player into `TrappedState`. Player mashes `action_sword` to escape (6 presses). Timeout calls `PlayerState.reduce_upgrade(&"shield", 1)`. Releases player on death.

`TrappedState` (`scenes/player/states/trapped_state.gd`, process_mode=ALWAYS): tracks captor, tick damage, mash counter, escape/timeout logic.

### Audio Coverage (Phase 8.4)

38 SFX call sites covering: sword_swing, sword_hit, shield_block, shield_reflect, shield_break, pickups (heart/rupee/generic), chest_open, door_unlock, bomb_place, bomb_explode, arrow_fire, hookshot_clink, hammer, player_hurt, player_death, enemy_hurt, enemy_death, enemy_shoot, engulf, escape, menu_move, menu_select, menu_back, text_blip, dash_start, block_push, switch, fall, transition, item_fanfare, item_fanfare_minor, lift, throw, bush_cut, error, clink.

BGM tracks via RoomData.music_track: overworld, dungeon, cave, dark_world, house. Direct play_bgm: title, game_over. Boss BGM deferred to Phase 9.

## Current Phase Status

Phase 1 complete, Phase 2 complete (2.1-2.7), Phase 3 complete (3.1-3.8), Phase 4 complete (4.1-4.4), Phase 5 complete (5.1), Phase 6 complete (6.1-6.6), Phase 7 complete (7.1-7.5), Phase 8 complete (8.1-8.4). 7 enemy types (5 base + Wizzrobe + Like-Like). Projectile system, pickup/loot system with 13 pickup types, weighted loot tables. 10 SKILL items, 16 UPGRADE items. 8x8 overworld with 7 biomes, 3 dungeons (4+8+8 rooms), 4 interiors. Lift/carry/throw with weight tiers (gloves upgrade). Game Over with death animation, continue/save-quit. Full audio coverage (38 SFX + 7 BGM tracks). Three test scenes: `debug/damage_formula_test.tscn` (38 tests), `debug/test_loot_table.tscn` (10 tests), `debug/test_player_state.tscn` (37 tests).

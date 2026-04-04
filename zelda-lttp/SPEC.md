# SPEC - Zelda: A Link to the Past - Mechanics Recreation in Godot 4.6

## Project Overview

A mechanics-faithful recreation of The Legend of Zelda: A Link to the Past (SNES, 1991) built in Godot 4.6. The project recreates game feel, interaction rules, combat rhythms, exploration flow, and progression structure without relying on original sprites or audio assets.

All visuals are rendered from primitive shapes, shaders, particles, and 2D lighting. Audio is implemented through a placeholder-first API that can log events now and accept real assets later without changing gameplay code.

### Goals

1. Recreate the core feel of ALTTP movement, combat, exploration, and progression.
2. Build the game in clean, modular Godot 4.6 architecture that can scale from a prototype to a multi-dungeon project.
3. Ship each phase as a playable vertical slice, not just a pile of unfinished systems.
4. Keep art and audio implementation legally clean by using original primitive visuals and placeholder-friendly hooks.

### Non-Goals

1. Pixel-perfect reproduction of SNES art, animation frames, or sound.
2. A byte-for-byte clone of ALTTP map layout, scripting, or hidden values.
3. Multiplayer, networking, procedural generation, or mod tooling.
4. Full content parity with the original game before the core game loop is stable.

### Design Principles

1. Mechanics first - if a system looks abstract but feels right, that is acceptable.
2. Primitive art, polished feedback - the visual language should be simple but deliberate.
3. Additive milestones - every phase must keep earlier work intact.
4. Data-driven content - items, enemies, drops, and dungeons should be defined by resources where practical.
5. Small, testable scenes - scenes own presentation and local behavior; autoloads own global state.
6. Swap-ready audio - gameplay calls stable methods, whether assets exist yet or not.

### Technical Foundation

- Engine: Godot 4.6, GDScript
- Target renderer: Compatibility
- Current repo state: [`project.godot`](/c:/dev/games-godot/zelda-lttp/project.godot) still declares Forward Plus, so Phase 1 must explicitly switch the project to Compatibility
- Resolution: 256x224 logical pixels, integer-scaled to 1024x896 by default
- Stretch settings: `display/window/stretch/mode = "viewport"`, `display/window/stretch/aspect = "keep"`
- Physics: Godot built-in 2D physics only
- Tile size: 16x16 base grid
- Health unit: 1 unit = half a heart
- Starting health: 6 units = 3 hearts
- Max health display: hearts, with 2 units per heart
- Magic meter: 0-128 units
- Input targets: keyboard and gamepad for all gameplay actions

### Core Conventions

- The player is a persistent scene instance created once per run and reparented into the active room's `Entities` node during transitions.
- The sword is always available. There is one active item slot, not two.
- Room scripts must expose a stable `room_id` string for persistence and analytics.
- Persistent flags use slash-separated keys, for example `world/light/overworld_0_0/chest_01_opened`.
- JSON save data must include a schema version so future migrations are possible.
- All phase deliverables must be testable from either the normal game flow or [`debug/debug_room.tscn`](/c:/dev/games-godot/zelda-lttp/debug/debug_room.tscn) once that scene exists.

---

## Directory Structure

```text
res://
|-- autoloads/
|   |-- event_bus.gd
|   |-- game_manager.gd
|   |-- inventory_manager.gd
|   |-- audio_manager.gd
|   |-- scene_manager.gd
|   `-- save_manager.gd
|-- components/
|   |-- state_machine.tscn/.gd
|   |-- state.gd
|   |-- health_component.tscn/.gd
|   |-- hitbox_component.tscn/.gd
|   |-- hurtbox_component.tscn/.gd
|   |-- loot_drop_component.tscn/.gd
|   |-- flash_component.tscn/.gd
|   `-- knockback_component.tscn/.gd
|-- scenes/
|   |-- main/
|   |   `-- main.tscn/.gd
|   |-- player/
|   |   |-- player.tscn/.gd
|   |   |-- states/
|   |   |   |-- player_state.gd
|   |   |   |-- idle_state.gd
|   |   |   |-- walk_state.gd
|   |   |   |-- attack_state.gd
|   |   |   |-- knockback_state.gd
|   |   |   |-- fall_state.gd
|   |   |   |-- dash_state.gd
|   |   |   |-- item_use_state.gd
|   |   |   `-- swim_state.gd
|   |   `-- components/
|   |       `-- shield_component.tscn/.gd
|   |-- enemies/
|   |   |-- base_enemy.tscn/.gd
|   |   |-- states/
|   |   |   |-- enemy_state.gd
|   |   |   |-- patrol_state.gd
|   |   |   |-- chase_state.gd
|   |   |   |-- attack_state.gd
|   |   |   `-- stunned_state.gd
|   |   `-- types/
|   |       |-- soldier.tscn/.gd
|   |       |-- octorok.tscn/.gd
|   |       |-- stalfos.tscn/.gd
|   |       |-- keese.tscn/.gd
|   |       `-- buzz_blob.tscn/.gd
|   |-- bosses/
|   |   |-- base_boss.tscn/.gd
|   |   `-- armos_knights.tscn/.gd
|   |-- items/
|   |   |-- base_item.gd
|   |   |-- sword_hitbox.tscn/.gd
|   |   |-- projectile_base.tscn/.gd
|   |   |-- arrow.tscn/.gd
|   |   |-- bomb.tscn/.gd
|   |   |-- boomerang.tscn/.gd
|   |   |-- hookshot.tscn/.gd
|   |   `-- pickup.tscn/.gd
|   |-- world/
|   |   |-- room.tscn/.gd
|   |   |-- door.tscn/.gd
|   |   |-- locked_door.tscn/.gd
|   |   |-- boss_door.tscn/.gd
|   |   |-- chest.tscn/.gd
|   |   |-- push_block.tscn/.gd
|   |   |-- switch.tscn/.gd
|   |   |-- pressure_plate.tscn/.gd
|   |   |-- pit.tscn/.gd
|   |   |-- conveyor_belt.tscn/.gd
|   |   |-- destructible.tscn/.gd
|   |   `-- npc.tscn/.gd
|   |-- effects/
|   |   |-- impact_particles.tscn
|   |   |-- magic_particles.tscn
|   |   `-- dust_particles.tscn
|   |-- ui/
|   |   |-- hud.tscn/.gd
|   |   |-- hearts_display.tscn/.gd
|   |   |-- magic_meter.tscn/.gd
|   |   |-- rupee_counter.tscn/.gd
|   |   |-- item_slot.tscn/.gd
|   |   |-- minimap.tscn/.gd
|   |   |-- inventory_screen.tscn/.gd
|   |   |-- dialog_box.tscn/.gd
|   |   |-- title_screen.tscn/.gd
|   |   `-- game_over_screen.tscn/.gd
|   `-- maps/
|       |-- light_world/
|       |   |-- overworld_0_0.tscn
|       |   `-- ...
|       |-- dark_world/
|       |   |-- overworld_0_0.tscn
|       |   `-- ...
|       `-- dungeons/
|           |-- dungeon_01/
|           |   |-- room_00.tscn
|           |   `-- ...
|           `-- ...
|-- resources/
|   |-- item_data.gd
|   |-- enemy_data.gd
|   |-- loot_table.gd
|   |-- dungeon_data.gd
|   |-- room_data.gd
|   |-- items/
|   |   |-- sword_01.tres
|   |   |-- bow.tres
|   |   `-- ...
|   |-- enemies/
|   |   |-- soldier.tres
|   |   `-- ...
|   |-- dungeon_data/
|   |   `-- dungeon_01.tres
|   |-- room_data/
|   |   `-- overworld_0_0.tres
|   `-- loot_tables/
|       |-- bush_loot.tres
|       `-- enemy_loot.tres
|-- shaders/
|   |-- water.gdshader
|   |-- damage_flash.gdshader
|   |-- screen_transition.gdshader
|   |-- dark_world_palette.gdshader
|   `-- lighting_overlay.gdshader
|-- audio/
|   |-- bgm/
|   `-- sfx/
`-- debug/
    `-- debug_room.tscn
```

---

## Primitive Visual Language

Every entity uses a simple, repeatable shape language so the game remains readable without sprites.

| Entity | Visual Rule |
|---|---|
| Player | Green pentagon torso, skin-tone circular head, directional cap triangle |
| Sword slash | White or pale yellow arc drawn during attack frames |
| Shield | Small colored polygon on the forward side of the player body |
| Soldier | Red rectangle body with small helmet triangle |
| Octorok | Red circle |
| Stalfos | White triangle |
| Keese | Purple diamond |
| Buzz Blob | Yellow circle with pulsing shader |
| Bush | Green circle cluster |
| Pot | Brown square with lighter rim |
| Chest | Brown rectangle with light lid strip |
| Arrow | Yellow triangle |
| Bomb | Gray circle with short fuse line |
| Hookshot | Blue-gray line and tip |
| Heart HUD | Red polygon heart |
| Rupee HUD | Green diamond |

Color should encode intent consistently:

- Green and warm neutrals for the player and friendly objects
- Red and orange for immediate threats
- Blue for water, magic, and stun or freeze states
- Gray and brown for structural environment
- Gold and yellow for key objectives, keys, and rewards

---

## Shared Systems and Data Rules

### Room Metadata

Each room scene should have a companion `RoomData` resource or exported fields on `room.gd` with:

- `room_id: StringName`
- `room_type: StringName` such as `overworld`, `cave`, `dungeon`
- `world_type: StringName` such as `light`, `dark`, `interior`
- `screen_coords: Vector2i` for overworld screens when applicable
- `music_track: StringName`
- `ambient_color: Color`
- `is_dark_room: bool`
- `neighbor_paths: Dictionary` keyed by `up`, `down`, `left`, `right`

This keeps transitions, music, save flags, and debug reporting consistent.

### Damage Typing

All hitboxes should expose a typed damage source so armor, shields, and enemy immunities can branch cleanly.

Recommended enum:

```gdscript
enum DamageType {
    CONTACT,
    SWORD,
    ARROW,
    BOMB,
    FIRE,
    ICE,
    MAGIC,
    PIT,
    WATER,
    SPIKE
}
```

### Save Schema

Save files must include at minimum:

```json
{
  "schema_version": 1,
  "slot": 1,
  "timestamp_utc": "2026-04-04T10:00:00Z",
  "player": {},
  "inventory": {},
  "game_state": {}
}
```

The exact payload can grow later, but `schema_version` is required from the first real save implementation onward.

### Debug Expectations

- `debug_room.tscn` should expose representative hazards, pickups, one destructible, one door, and at least one enemy archetype as systems land.
- Any new core interaction should be testable in isolation without needing a full overworld.
- Audio placeholder logs should include a category prefix so noisy logs stay readable, for example `[Audio][SFX] sword_swing`.

---

## Phase 1: Core Foundation

**Milestone**: "Link Walks Around a Room"

### 1.1 Project Configuration

- Switch the project renderer from Forward Plus to Compatibility
- Resolution: 256x224 with viewport stretch and integer-friendly upscaling
- Default window: 1024x896
- Physics tick: leave at Godot default unless profiling proves it needs adjustment
- Input map:
  - `move_up`, `move_down`, `move_left`, `move_right`
  - `action_sword`
  - `action_item`
  - `action_dash`
  - `action_shield`
  - `interact`
  - `pause`
- Suggested keyboard bindings:
  - Move: WASD and arrows
  - Sword: `J` and `X`
  - Item: `K` and `Z`
  - Dash: `L` and `C`
  - Shield: Left Shift
  - Interact: `E` and Space
  - Pause: Escape and Enter
- Suggested gamepad bindings:
  - Move: left stick and d-pad
  - Sword: east face button
  - Item: west face button
  - Dash: south face button
  - Shield: left shoulder
  - Interact: north face button
  - Pause: Start

Physics layers:

| Layer | Name | Used By |
|---|---|---|
| 1 | World | Walls, solid terrain, room geometry |
| 2 | Player | Player body and shield component |
| 3 | Enemies | Enemy bodies and hurtboxes |
| 4 | PlayerAttacks | Sword hitbox and player projectiles |
| 5 | EnemyAttacks | Enemy projectiles and enemy contact hitboxes |
| 6 | Interactables | Chests, signs, NPCs, pots, bushes |
| 7 | Hazards | Pits, spikes, water hazards before flippers |
| 8 | Triggers | Room transitions, cutscene zones, sensors |

Autoload registration order:

1. `EventBus`
2. `GameManager`
3. `InventoryManager`
4. `AudioManager`
5. `SceneManager`
6. `SaveManager`

### 1.2 Main Scene

`scenes/main/main.tscn` is the always-loaded root scene.

Node layout:

- `Main` (`Node`)
  - `World` (`Node2D`)
  - `HUDLayer` (`CanvasLayer`, layer 10)
  - `DialogLayer` (`CanvasLayer`, layer 15)
  - `TransitionOverlay` (`CanvasLayer`, layer 20)
  - `PauseLayer` (`CanvasLayer`, layer 25, `process_mode = ALWAYS`)
  - `DebugLayer` (`CanvasLayer`, optional, editor/debug only)

Rules:

- `SceneManager` swaps room scenes only under `World`
- `Main` itself is never replaced during gameplay
- Title screen, overworld rooms, dungeon rooms, and game over screen are all children loaded beneath `World`
- The persistent player instance is spawned once and inserted into the active room's `Entities` node

### 1.3 Autoload Responsibilities

**EventBus**

Pure signal hub. Initial signals:

- `player_health_changed(current, max)`
- `player_magic_changed(current, max)`
- `player_rupees_changed(amount)`
- `player_damaged(amount, source_type)`
- `player_died()`
- `enemy_defeated(enemy_type, position)`
- `item_acquired(item_id)`
- `room_transition_requested(target_room_id, entry_point)`
- `world_switch_requested(target_world_type)`
- `dialog_requested(lines)`
- `screen_shake_requested(intensity, duration)`

**GameManager**

Owns run-level state:

- Current world type
- Current dungeon id and room id
- Global flags dictionary
- Pause state
- Last safe player position
- Current save slot

Public methods:

- `set_flag(key: StringName, value: Variant) -> void`
- `get_flag(key: StringName, default_value := false) -> Variant`
- `has_flag(key: StringName) -> bool`

**SceneManager**

Owns:

- Loading and unloading room scenes
- Room transition timing
- Reparenting the persistent player into the new room
- Applying room camera limits
- Starting room music from room metadata

Implementation notes:

- Use `ResourceLoader.load_threaded_request()` for room preloading
- Maintain `current_room`, `current_room_id`, and `current_screen_coords`
- Provide a blocking fallback load path so the game still works if threaded loading is unavailable in a debug context

**AudioManager**

Placeholder-first audio API:

- Two `AudioStreamPlayer` children for BGM crossfade
- Pool of 8 `AudioStreamPlayer` nodes for SFX
- `play_bgm(track_name)`
- `stop_bgm()`
- `play_sfx(sfx_name)`
- `set_bgm_volume(db)`
- `set_sfx_volume(db)`

Behavior:

- If the requested file exists in `res://audio/bgm` or `res://audio/sfx`, play it
- Otherwise log a tagged placeholder message
- Gameplay code must never branch based on whether a real asset exists

**InventoryManager**

Owns:

- One equipped active item slot
- Owned active items
- Passive upgrade tiers: sword, armor, shield, gloves
- Consumables: rupees, arrows, bombs
- Dungeon counters: small keys, big keys, map, compass per dungeon
- Health, max health, magic, max magic
- Heart pieces

Public methods:

- `add_item(item_id)`
- `equip_item(item_id)`
- `has_item(item_id) -> bool`
- `spend_rupees(amount) -> bool`
- `spend_ammo(kind, amount) -> bool`
- `add_key(dungeon_id, amount := 1)`
- `use_key(dungeon_id) -> bool`

**SaveManager**

Phase 1 behavior:

- Stub methods may log instead of writing real files
- Method names and payload shape should already match the final save system

Final responsibility:

- Serialize `GameManager`, `InventoryManager`, and player position to `user://save_{slot}.json`
- Preserve `schema_version`

### 1.4 Player Character

`scenes/player/player.tscn`

- `Player` (`CharacterBody2D`)
  - `CollisionShape2D`
  - `PlayerBody` (`Node2D`, custom `_draw()`)
  - `SwordHitbox` (`Area2D` or child scene with `HitboxComponent`)
  - `ShieldComponent` (`Area2D`)
  - `HurtboxComponent` (`Area2D`)
  - `InteractionProbe` (`ShapeCast2D` or `Area2D`)
  - `StateMachine`
  - `AnimationPlayer`
  - `Camera2D`
  - `DashDustSpawner` (`GPUParticles2D`)
  - `PointLight2D`

Core properties:

- `facing_direction: Vector2`
- `move_input: Vector2`
- `speed := 90.0`
- `push_speed := 30.0`
- `dash_speed_multiplier := 2.5`
- `last_safe_position: Vector2`

Rules:

- Movement is 8-directional
- Diagonal movement must be normalized
- The player collision box should fit a 16-pixel corridor comfortably, approximately 12x14 pixels
- `facing_direction` persists when idle
- `action_dash` does nothing until Pegasus Boots are acquired

### 1.5 Player State Machine

Use a generic reusable `StateMachine` node under `components/`.

Phase 1 required states:

| State | Behavior |
|---|---|
| Idle | No movement. Transition to Walk on movement input. Transition to Attack on sword input. |
| Walk | 8-direction movement at base speed. Transition to Idle when input ends. |
| Attack | Short sword swing, roughly 0.25-0.3 seconds. Player movement locked. |
| Knockback | Brief forced motion after damage, then return to Idle. |
| Fall | Triggered by pits or fallback hazards. Shrink or scale tween, respawn at last safe position, apply damage. |

Later states:

- `DashState` after Pegasus Boots
- `ItemUseState` after active items exist
- `SwimState` after Flippers
- `LiftState`, `CarryState`, and `ThrowState` after gloves

Input buffering:

- Buffer `action_sword`, `action_item`, and `action_dash` for 0.1 seconds
- Consume the oldest valid buffered action when the current state becomes interruptible

### 1.6 Camera System

Player-owned `Camera2D`:

- Overworld rooms use bounded follow with smoothing
- Dungeon rooms use fixed room framing
- Screen transitions temporarily override free follow

Defaults:

- `position_smoothing_enabled = true`
- `position_smoothing_speed = 8.0`

Transition behavior:

- Overworld edge crossing: 0.5-second camera scroll and short player auto-walk
- Dungeon door transition: fade out, swap room, fade in

### 1.7 Base Room Structure

`scenes/world/room.tscn`

- `Room` (`Node2D`)
  - `Terrain` (`TileMapLayer`)
  - `Overlay` (`TileMapLayer`)
  - `Entities` (`Node2D`, `y_sort_enabled = true`)
  - `Transitions` (`Node2D`)
  - `EntryPoints` (`Node2D` containing `Marker2D`s)
  - `NavigationRegion2D`
  - `CanvasModulate`
  - Optional `PointLight2D` nodes

Rules:

- `Terrain` owns floor, walls, hazards, and collision
- `Overlay` owns visual elements that draw above the player
- `Entities` contains enemies, NPCs, pickups, interactables, and the persistent player instance
- Entry points are named markers used by `SceneManager`

Tile behavior by type:

| Tile Type | Behavior |
|---|---|
| Floor | Walkable |
| Wall | Solid collision |
| Water | Hazard or blocked movement before Flippers; swimmable after Flippers |
| Pit | Triggers Fall state |
| Ledge | One-way traversal where appropriate |
| Conveyor | Adds velocity while overlapping |
| Ice | Reduced friction and longer slide distance |

Room loading strategy:

- Dungeon transitions load one room at a time
- Overworld scroll transitions temporarily load current room plus destination room
- `SceneManager` should preload the four cardinal overworld neighbors when possible

Persistence:

- Enemies respawn when re-entering a room unless a specific room script overrides that behavior for a boss or scripted event
- Chests, solved push blocks, toggled switches, opened boss doors, and world-state changes must restore from `GameManager` flags

### 1.8 Phase 1 Deliverable

Acceptance criteria:

1. One playable room exists with walls, at least one hazard, and at least one valid entry point marker.
2. The player can move in 8 directions, swing a visible sword arc, take damage, and recover from knockback.
3. The camera remains bounded inside the room.
4. HUD shows hearts and updates on damage.
5. Audio calls log correctly even with no real assets present.

---

## Phase 2: Combat System

**Milestone**: "Link Fights Enemies"

### 2.1 Core Combat Components

**HurtboxComponent**

- `Area2D` that receives hits
- Tracks invincibility frames
- Emits `hurt(hitbox_data)` with damage, source direction, and damage type

**HitboxComponent**

- `Area2D` that deals damage
- Properties:
  - `damage: int`
  - `damage_type: DamageType`
  - `knockback_force: float`
  - `effect: HitEffect`
  - `source_team: StringName` such as `player` or `enemy`

**KnockbackComponent**

- Applies decelerating knockback over a short window

**FlashComponent**

- Brief white-flash visual using shader or modulation tween

Recommended `HitEffect` enum:

```gdscript
enum HitEffect {
    NONE,
    STUN,
    FREEZE,
    BURN
}
```

### 2.2 Enemy Data Resource

```gdscript
class_name EnemyData extends Resource

@export var id: StringName
@export var display_name: String
@export var max_health: int
@export var contact_damage: int
@export var knockback_resistance: float
@export var speed: float
@export var detection_radius: float
@export var attack_range: float
@export var drop_table: LootTable
@export var color: Color
@export var damage_immunities: Array[int]
@export var contact_enabled: bool = true
```

Keep balance data in resources, not hard-coded in enemy behavior scripts.

### 2.3 Enemy Base Scene

`scenes/enemies/base_enemy.tscn`

- `BaseEnemy` (`CharacterBody2D`)
  - `EnemyBody`
  - `CollisionShape2D`
  - `HurtboxComponent`
  - `ContactHitbox`
  - `HealthComponent`
  - `KnockbackComponent`
  - `FlashComponent`
  - `LootDropComponent`
  - `StateMachine`
  - `NavigationAgent2D`
  - `DetectionZone`

Behavior:

- Enemies use `EnemyData` for stats
- Death triggers particles, loot roll, `EventBus.enemy_defeated`, then `queue_free()`
- Navigation may fall back to direct vector pursuit in small rooms where a nav mesh is unnecessary

Enemy state set:

| State | Behavior |
|---|---|
| Patrol | Random walk, fixed path, or stationary idle |
| Chase | Pursue player once detected |
| Attack | Contact rush, projectile fire, or lunge |
| Stunned | Temporary immobilize from specific effects |

### 2.4 Initial Enemy Set

| Enemy | Shape | Behavior |
|---|---|---|
| Soldier | Red rectangle with helmet | Patrol, chase, lunge |
| Octorok | Red circle | Slow move, cardinal projectile shots |
| Keese | Purple diamond | Fluttering contact attacker |
| Stalfos | White triangle | Random walk, bone projectile |
| Buzz Blob | Yellow circle | Contact damage, immune to sword |

### 2.5 Projectile System

`projectile_base.tscn`

- Root type: `Area2D`
- Required properties:
  - `speed`
  - `damage`
  - `damage_type`
  - `direction`
  - `lifetime`
  - `pierce`
  - `deflectable`
  - `source_team`

Rules:

- Destroy on world collision unless explicitly bouncing
- Damage valid opposing hurtboxes
- Do not damage same-team actors by default
- Specialized subclasses override behavior, for example boomerang return, hookshot retract, bomb explode

### 2.6 Loot Drops

**LootTable**

- Weighted entries: `item_id`, `weight`, `quantity_min`, `quantity_max`
- `roll()` returns zero or more pickup payloads

**LootDropComponent**

- Spawns pickups on death or object destruction
- Pickups bob visually and magnetize lightly toward the player on overlap or close collection radius
- Pickups despawn after a timeout unless the design later chooses permanence

Pickup types:

- Heart: restore 1 health unit
- Green rupee: +1
- Blue rupee: +5
- Red rupee: +20
- Magic jar: restore magic
- Arrow bundle
- Bomb bundle

### 2.7 Phase 2 Deliverable

Acceptance criteria:

1. At least three enemy types are fightable in one room.
2. Player and enemies both use hitbox and hurtbox components with knockback and invincibility frames.
3. Enemies drop pickups through weighted tables.
4. Shield-blockable projectiles and non-blockable damage sources are distinguishable in data.

---

## Phase 3: Items and Inventory

**Milestone**: "Link Has Equipment"

### 3.1 Item Data Resource

```gdscript
class_name ItemData extends Resource

@export var id: StringName
@export var display_name: String
@export var description: String
@export var item_type: ItemType
@export var icon_color: Color
@export var icon_shape: PackedVector2Array
@export var magic_cost: int
@export var ammo_type: StringName
@export var ammo_cost: int
@export var tier: int
@export var use_script: Script
@export var unlock_flag: StringName
```

Suggested item type enum:

```gdscript
enum ItemType {
    ACTIVE,
    PASSIVE,
    COLLECTIBLE
}
```

### 3.2 Active Items

Each active item extends a common base with `activate(player, direction)`.

| Item | Mechanic |
|---|---|
| Bow | Fires an arrow in the facing direction, costs 1 arrow |
| Bomb | Places a timed bomb, costs 1 bomb |
| Boomerang | Travels out and returns, stuns enemies, can collect pickups |
| Hookshot | Extends in facing direction, pulls player to hookable targets |
| Lamp | Creates a temporary light source and lights torches |
| Magic Powder | Short-range cone effect, used for transformations or puzzle interactions |
| Fire Rod | Ranged fire projectile, lights torches |
| Ice Rod | Ranged ice projectile, freezes enemies |
| Hammer | Short melee strike, pounds pegs, flips certain enemies |

### 3.3 Passive Upgrades

| Upgrade | Tiers | Effect |
|---|---|---|
| Sword | 1-4 | Damage increase, stronger slash visuals, sword beam at full health |
| Armor | 1-3 | Incoming damage reduction |
| Shield | 1-3 | Blocks additional projectile classes |
| Gloves | 1-2 | Lift light or heavy objects |
| Flippers | Boolean | Enter water and swim |
| Pegasus Boots | Boolean | Enables dash |
| Moon Pearl | Boolean | Prevents Dark World transformation |

Sword beam rule:

- At full health, sword swings may emit a forward beam once the sword tier supports it
- Sword beam does not consume magic

### 3.4 Shield Mechanics

The shield is primarily passive, matching ALTTP.

Base behavior:

- While idle or walking, the shield protects the player's forward-facing arc
- The player does not gain omnidirectional protection
- Holding `action_shield` is an optional precision stance:
  - locks facing
  - slows movement
  - widens the frontal block window

Shield tiers:

| Tier | Blocks |
|---|---|
| 1 | Rocks, arrows |
| 2 | Tier 1 plus fireballs and beams |
| 3 | Tier 2 plus stronger magic projectiles, reflects select shots |

Implementation note:

- Incoming projectiles should declare a `projectile_class` or equivalent data field
- Shield logic should decide block, deflect, or reflect from data, not enemy-specific special cases

### 3.5 Inventory Screen

Pause-driven full-screen overlay:

- `get_tree().paused = true`
- Inventory UI nodes use `process_mode = ALWAYS`

Layout:

- Top: one equipped active item slot and a selectable grid of owned active items
- Middle: passive gear display for sword, armor, shield, gloves
- Bottom: collectible status such as heart pieces and dungeon collectibles
- Cursor: yellow outline rectangle
- Item icons: generated from `icon_shape` and `icon_color`

### 3.6 Phase 3 Deliverable

Acceptance criteria:

1. The player can pause, equip an active item, and resume play.
2. At least four active items are functional.
3. Ammo and magic consumption are enforced through `InventoryManager`.
4. Shield tiers and passive upgrades visibly affect gameplay.

---

## Phase 4: World Structure and Transitions

**Milestone**: "Explorable Overworld"

### 4.1 Overworld Grid

- One screen = 256x224 pixels
- Naming convention: `overworld_X_Y.tscn`
- `SceneManager` tracks `current_screen_coords: Vector2i`

Screen-edge transition flow:

1. Detect exit direction
2. Disable free player control
3. Load or reveal adjacent room
4. Scroll camera over 0.5 seconds
5. Auto-walk player a short distance into the new screen
6. Free old room and re-enable control

Initial content target:

- 4x4 light-world overworld
- Biome variation through tile color and object density

### 4.2 Interior and Cave Transitions

`Door` scene requirements:

- Trigger method: walk-in or `interact`, depending on door type
- Exported fields:
  - `target_scene`
  - `target_entry_point`
  - `transition_style`

Transition styles:

- `fade`
- `iris`
- `instant` for debugging only

### 4.3 Dungeon Structure

`DungeonData` resource:

```gdscript
class_name DungeonData extends Resource

@export var dungeon_id: StringName
@export var dungeon_name: String
@export var rooms: Dictionary
@export var starting_room: Vector2i
@export var boss_room: Vector2i
@export var small_key_count: int
@export var boss_id: StringName
```

Notes:

- Dictionary keys can be `Vector2i` in memory, but save serialization should convert them to strings such as `"2,1"`
- Dungeon rooms use fade transitions rather than side-scroll transitions

Dungeon elements:

- `LockedDoor`: consumes one small key
- `BossDoor`: requires big key
- `Chest`: opens once and persists
- `PushBlock`: pushes one tile and persists if puzzle design needs it
- `Switch`: toggles linked elements
- `PressurePlate`: reacts to player or block weight
- `Pit`: fall hazard or floor-drop trigger
- `ConveyorBelt`: continuous directional push

### 4.4 Light World and Dark World

The game supports paired overworld maps with shared coordinates.

Dark World requirements:

- Distinct palette or `CanvasModulate`
- Different room scenes or room variants
- Tougher enemy distribution

Magic Mirror behavior:

1. Activate from the Dark World
2. Run swirl transition
3. Place player at mirrored coordinates in the Light World
4. Spawn temporary return portal if that mechanic is kept

Without Moon Pearl:

- Entering the Dark World transforms the player
- Transformed state limits sword and item access unless later design changes it deliberately

### 4.5 Phase 4 Deliverable

Acceptance criteria:

1. A 4x4 overworld scrolls correctly between adjacent screens.
2. At least two interiors or caves can be entered and exited.
3. One dungeon with at least four rooms includes a key, locked door, chest, and push-block or switch puzzle.
4. Light/Dark World switching works for at least a 2x2 subset.

---

## Phase 5: Bosses and Advanced Combat

**Milestone**: "First Dungeon Complete"

### 5.1 Boss Base System

Bosses extend enemy rules and add:

- `phase` tracking by health thresholds or scripted triggers
- Boss health bar UI
- Camera lock to room bounds
- Boss door closure on encounter start
- Brief invulnerability and flourish on phase changes

### 5.2 Armos Knights

Boss structure:

- One controller node manages six knight instances

Phase 1:

- Knights hop in coordinated patterns
- Contact damage on collision
- Surviving knights increase aggression as others die

Phase 2:

- Final knight changes color to red
- Movement and leap speed increase
- Landing point telegraph appears before impact

Defeat reward:

- Heart Container
- Warp tile

### 5.3 Dungeon Completion Flow

On boss defeat:

1. Set dungeon completion flag
2. Spawn Heart Container pickup
3. Fully heal player on pickup
4. Spawn warp tile back to dungeon entrance

### 5.4 Phase 5 Deliverable

Acceptance criteria:

1. One dungeon can be entered, cleared, and exited end to end.
2. The boss has at least two distinct phases.
3. Completion flagging, reward drop, and exit warp all work in one continuous run.

---

## Phase 6: HUD, UI, and Polish

**Milestone**: "Feels Like a Game"

### 6.1 HUD

HUD lives on `CanvasLayer` 10 and remains active in gameplay scenes.

Elements:

- Hearts at top-left
- Magic meter under hearts
- Rupee count near upper left or center-left
- Equipped item slot near top-right
- Dungeon minimap when applicable
- Small key count in dungeons

Rules:

- HUD listens to signals rather than polling managers every frame
- Heart rendering supports full, half, and empty states
- Hide dungeon-only widgets when outside dungeons

### 6.2 Dialog System

Dialog box requirements:

- Bottom-of-screen panel
- Typewriter effect
- `interact` advances or fast-forwards text
- Supports multi-page line arrays

Triggered through:

- `EventBus.dialog_requested(lines)`

### 6.3 Shader Effects

| Shader | Effect |
|---|---|
| `screen_transition.gdshader` | Iris and fade transitions |
| `damage_flash.gdshader` | White flash on hit |
| `water.gdshader` | UV distortion and subtle color cycling |
| `dark_world_palette.gdshader` | Palette shift for Dark World tone |
| `lighting_overlay.gdshader` | Optional room mood or vignette work |

### 6.4 Feedback and Juice

- Screen shake via `Camera2D.offset`
- Squash and stretch on attacks and landings
- Impact particles on hits, kills, and explosions
- Dash dust during boots movement
- Ambient particles by biome
- Per-room `CanvasModulate`
- Flickering torch lights in dark interiors

### 6.5 Title Screen

Minimum title screen features:

- New Game
- Continue
- Options placeholder
- Animated background treatment

`Continue` should be disabled or hidden when no save file exists.

### 6.6 Phase 6 Deliverable

Acceptance criteria:

1. The game has a functional title screen, HUD, dialog box, and transitions.
2. Combat and movement have visible feedback through particles, flashes, or shake.
3. The project feels coherent despite using primitive art.

---

## Phase 7: Expanded Content

**Milestone**: "Full Game Loop"

### 7.1 Additional Dungeons

- Dungeon 2: conveyor and pit-heavy spaces, projectile-pattern boss
- Dungeon 3: dark rooms, moving platform or traversal-heavy spaces, multi-phase boss

Each dungeon should include:

- Entrance and completion loop
- 6-10 rooms
- Map, compass, big key
- 2-4 small keys
- Unique boss
- Heart Container reward

### 7.2 Heart Pieces

Four pieces combine into one heart container.

Sources:

- Optional caves
- Mini-puzzles
- NPC rewards
- Hidden chests
- Future mini-games if added

### 7.3 NPC System

NPC scene expectations:

- Static or wandering movement
- Primitive visual shape
- Interact area
- `dialog_lines`
- Optional visibility or dialog gating by flag

### 7.4 Destructible Objects

Objects:

- Bushes
- Pots
- Skulls

Behaviors:

- Destroyable by sword, dash, or throw depending on object type
- Can spawn loot
- Lift and throw once gloves are available

### 7.5 Expanded Overworld

World target grows from 4x4 to 8x8.

Biomes:

- Field
- Forest
- Mountain
- Desert
- Lake
- Village
- Graveyard

### 7.6 Save and Load

Real save system requirements:

- Three save slots
- Slot metadata for UI, including play time and last save timestamp
- Save points or safe save triggers
- Load from title screen

Saved data must include:

- Player room id and position
- Current world type
- InventoryManager state
- GameManager flags
- Dungeon progression state

### 7.7 Phase 7 Deliverable

Acceptance criteria:

1. Three dungeons are completable.
2. Save and load work across multiple slots.
3. Overworld includes NPCs, optional rewards, and destructible interactions.

---

## Phase 8: Advanced Mechanics

**Milestone**: "Feature Complete"

### 8.1 Swimming

With Flippers:

- Enter water instead of being rejected or damaged
- Movement speed reduced from normal ground speed
- Ripple particles and smaller body profile

Without Flippers:

- Water acts as a hazard or blocked terrain, depending on room design

### 8.2 Lifting and Throwing

With gloves:

- `interact` lifts a valid object in front of the player
- Object attaches above player while carried
- Sword use is disabled while carrying unless deliberately changed later
- Throw launches object as a simple projectile

Tier rules:

- Power Glove lifts light objects
- Titan's Mitt lifts heavy objects

### 8.3 Magic System

Max magic: 128 units

Suggested costs:

- Lamp: 4
- Fire Rod: 8
- Ice Rod: 8
- Magic Powder: 4
- Medallion-class future items: 32-64

Refills:

- Small magic jar: 16
- Large magic jar: full or large partial refill
- Half Magic upgrade halves future costs

Spin attack should not consume magic.

### 8.4 Game Over

Flow:

1. Player health reaches zero
2. Play death animation and transition
3. Show game over screen
4. Offer Continue or Save and Quit

Continue behavior:

- Respawn at dungeon entrance or designated overworld safe point
- Restore to 3 hearts

### 8.5 Advanced Enemies

| Enemy | Behavior |
|---|---|
| Wizzrobe | Teleports, telegraphs, fires magic, relocates |
| Like-Like | Engulfs on contact, can threaten shield equipment |
| Moldorm | Multi-segment body, only tail vulnerable |

### 8.6 Audio Hookup Coverage

All major systems should already call `AudioManager` even if assets are absent.

Coverage list:

- BGM: overworld biomes, dungeons, bosses, title, game over, caves, Dark World
- SFX: sword swing and hit, shield block, pickups, chest open, door unlock, bomb place and explode, arrow fire, hookshot, player hurt and death, enemy hurt and death, menu move and select, text blip, dash, push block, switch toggle, fall, transitions

Asset convention:

- `res://audio/bgm/{name}.ogg`
- `res://audio/sfx/{name}.ogg`

### 8.7 Phase 8 Deliverable

Acceptance criteria:

1. Swimming, lifting, throwing, magic consumption, and game over all work in normal gameplay.
2. Advanced enemies meaningfully exercise those systems.
3. Audio coverage is documented and already wired through gameplay code.

---

## Architecture Reference

### Signal Flow: Player Takes Damage

```text
Enemy hitbox overlaps player hurtbox
  -> HurtboxComponent validates invincibility and source team
  -> HurtboxComponent emits hurt(hit_data)
  -> Player receives hit_data
  -> Armor and shield rules modify or reject hit
  -> HealthComponent.take_damage(final_damage)
  -> EventBus.player_health_changed(current, max)
  -> FlashComponent.flash()
  -> KnockbackComponent.apply(direction, force)
  -> StateMachine.transition_to("knockback")
  -> AudioManager.play_sfx("player_hurt")
  -> EventBus.screen_shake_requested(intensity, duration)
  -> If health <= 0, EventBus.player_died()
```

### Base State Class

```gdscript
class_name State extends Node

var state_machine: StateMachine
var actor: Node

func enter() -> void:
    pass

func exit() -> void:
    pass

func handle_input(_event: InputEvent) -> void:
    pass

func physics_update(_delta: float) -> void:
    pass
```

Player states should type `actor` more specifically in their subclass, for example `Player`, and enemy states should type it as `BaseEnemy`.

### State Machine Pattern

```gdscript
class_name StateMachine extends Node

@export var initial_state: State

var current_state: State
var states: Dictionary = {}

func _ready() -> void:
    var parent := get_parent()

    for child in get_children():
        if child is State:
            var key := StringName(child.name.to_lower())
            states[key] = child
            child.state_machine = self
            child.actor = parent

    current_state = initial_state
    if current_state:
        current_state.enter()

func _physics_process(delta: float) -> void:
    if current_state:
        current_state.physics_update(delta)

func _unhandled_input(event: InputEvent) -> void:
    if current_state:
        current_state.handle_input(event)

func transition_to(state_name: StringName) -> void:
    if not states.has(state_name):
        push_warning("Unknown state: %s" % state_name)
        return

    if current_state:
        current_state.exit()

    current_state = states[state_name]
    current_state.enter()
```

### Item Resource Example

```gdscript
[gd_resource type="Resource" script_class="ItemData"]

[resource]
id = &"bow"
display_name = "Bow"
item_type = 0
icon_color = Color(0.6, 0.4, 0.2, 1.0)
magic_cost = 0
ammo_type = &"arrows"
ammo_cost = 1
unlock_flag = &"items/bow"
```

### Collision Masks

| Entity | Layer | Mask |
|---|---|---|
| Player body | 2 | 1, 7 |
| Player hurtbox | 2 | 5 |
| Sword hitbox | 4 | 3, 6 |
| Player projectile | 4 | 1, 3, 6 |
| Shield component | 2 | 5 |
| Enemy body | 3 | 1, 3 |
| Enemy hurtbox | 3 | 4 |
| Enemy contact hitbox | 5 | 2 |
| Enemy projectile | 5 | 1, 2 |
| Pickups | 6 | 2 |
| Triggers | 8 | 2 |

---

## Implementation Priority

| Phase | Milestone | Key Systems |
|---|---|---|
| 1 | Link Walks Around a Room | Movement, room loading, player, HUD stub, autoloads |
| 2 | Link Fights Enemies | Combat components, enemy archetypes, drops |
| 3 | Link Has Equipment | Inventory, active items, passive upgrades |
| 4 | Explorable Overworld | Screen transitions, dungeon structure, world switching |
| 5 | First Dungeon Complete | Boss architecture, full dungeon completion loop |
| 6 | Feels Like a Game | HUD polish, dialog, transitions, particles, title screen |
| 7 | Full Game Loop | Additional dungeons, NPCs, heart pieces, save/load |
| 8 | Feature Complete | Swimming, lifting, throwing, magic, game over, advanced enemies |

Rules for phase completion:

1. No phase should require throwing away previous systems.
2. Every phase must leave the game in a runnable state.
3. New content should plug into existing resources and managers instead of bypassing them.
4. If a shortcut is taken for milestone speed, it must be written down in the spec or tracked as explicit tech debt.

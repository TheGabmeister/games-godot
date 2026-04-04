# SPEC — Zelda: A Link to the Past — Mechanics Recreation in Godot 4.6

## Project Overview

A mechanics-faithful recreation of The Legend of Zelda: A Link to the Past (SNES, 1991) built in Godot 4.6. Focuses on recreating **game systems and mechanics**, not pixel-perfect visuals. All art is rendered using Godot primitive shapes (`Polygon2D`, `_draw()`, `ColorRect`), shaders, particles, and 2D lighting. Audio uses a skeleton system that logs events and is designed for easy asset swapping later.

### Design Principles

1. **Mechanics first** — every system should feel like ALTTP to play, even if it doesn't look like it.
2. **Primitive art, polished effects** — no sprites. Use shapes, shaders, particles, and lighting to compensate.
3. **Incremental milestones** — each phase produces a playable build.
4. **Godot best practices** — scenes as components, signals for decoupling, autoloads for global systems, resources for data, state machines for behavior.
5. **Swap-ready audio** — placeholder system uses the same API real audio will, making asset integration trivial.

### Technical Foundation

- **Engine**: Godot 4.6, GDScript
- **Renderer**: Compatibility (switch from Forward Plus — this is a 2D-only project, Compatibility is lighter and sufficient)
- **Resolution**: 256×224 logical (SNES native), scaled up with integer scaling. `stretch_mode = "viewport"`, `stretch_aspect = "keep"`, window 1024×896 (4×).
- **Physics**: 2D only (built-in 2D physics)
- **Tile size**: 16×16 base grid
- **Health unit**: 1 unit = half heart. Max health displayed as hearts (2 units each). Starting health: 6 (3 hearts).
- **Input**: Keyboard + gamepad. All input actions mapped to both.

---

## Directory Structure

```
res://
├── autoloads/                  # Global singleton scripts
│   ├── game_manager.gd
│   ├── scene_manager.gd
│   ├── audio_manager.gd
│   ├── event_bus.gd
│   ├── save_manager.gd
│   └── inventory_manager.gd
├── components/                 # Reusable scene-components
│   ├── state_machine.tscn/.gd
│   ├── state.gd                # Base State class
│   ├── health_component.tscn/.gd
│   ├── hitbox_component.tscn/.gd
│   ├── hurtbox_component.tscn/.gd
│   ├── loot_drop_component.tscn/.gd
│   ├── flash_component.tscn/.gd
│   └── knockback_component.tscn/.gd
├── scenes/
│   ├── player/
│   │   ├── player.tscn/.gd
│   │   ├── states/             # Player state machine scripts
│   │   │   ├── player_state.gd
│   │   │   ├── idle_state.gd
│   │   │   ├── walk_state.gd
│   │   │   ├── dash_state.gd
│   │   │   ├── attack_state.gd
│   │   │   ├── spin_attack_state.gd
│   │   │   ├── item_use_state.gd
│   │   │   ├── fall_state.gd
│   │   │   └── knockback_state.gd
│   │   └── components/
│   │       └── shield_component.tscn/.gd
│   ├── enemies/
│   │   ├── base_enemy.tscn/.gd
│   │   ├── states/
│   │   │   ├── enemy_state.gd
│   │   │   ├── patrol_state.gd
│   │   │   ├── chase_state.gd
│   │   │   ├── attack_state.gd
│   │   │   └── stunned_state.gd
│   │   └── types/              # Specific enemies inheriting base_enemy
│   │       ├── soldier.tscn/.gd
│   │       ├── octorok.tscn/.gd
│   │       ├── stalfos.tscn/.gd
│   │       └── keese.tscn/.gd
│   ├── bosses/
│   │   ├── base_boss.tscn/.gd
│   │   └── armos_knights.tscn/.gd
│   ├── items/
│   │   ├── base_item.gd
│   │   ├── sword_hitbox.tscn/.gd
│   │   ├── projectile_base.tscn/.gd
│   │   ├── arrow.tscn/.gd
│   │   ├── bomb.tscn/.gd
│   │   ├── boomerang.tscn/.gd
│   │   ├── hookshot.tscn/.gd
│   │   └── pickup.tscn/.gd        # Collectible drops (hearts, rupees, ammo)
│   ├── world/
│   │   ├── room.tscn/.gd
│   │   ├── door.tscn/.gd
│   │   ├── locked_door.tscn/.gd
│   │   ├── push_block.tscn/.gd
│   │   ├── switch.tscn/.gd
│   │   ├── pressure_plate.tscn/.gd
│   │   ├── chest.tscn/.gd
│   │   ├── pit.tscn/.gd
│   │   ├── conveyor_belt.tscn/.gd
│   │   ├── destructible.tscn/.gd
│   │   └── npc.tscn/.gd
│   ├── effects/
│   │   ├── impact_particles.tscn
│   │   ├── magic_particles.tscn
│   │   └── dust_particles.tscn
│   ├── ui/
│   │   ├── hud.tscn/.gd
│   │   ├── hearts_display.tscn/.gd
│   │   ├── magic_meter.tscn/.gd
│   │   ├── rupee_counter.tscn/.gd
│   │   ├── item_slot.tscn/.gd
│   │   ├── minimap.tscn/.gd
│   │   ├── inventory_screen.tscn/.gd
│   │   ├── dialog_box.tscn/.gd
│   │   └── title_screen.tscn/.gd
│   ├── main/
│   │   └── main.tscn/.gd          # Root scene: holds World, HUD, TransitionOverlay
│   └── maps/
│       ├── light_world/
│       │   ├── overworld_0_0.tscn
│       │   └── ...
│       ├── dark_world/
│       │   ├── overworld_0_0.tscn
│       │   └── ...
│       └── dungeons/
│           ├── dungeon_01/
│           │   ├── room_00.tscn
│           │   └── ...
│           └── ...
├── resources/
│   ├── item_data.gd            # ItemData Resource class
│   ├── enemy_data.gd           # EnemyData Resource class
│   ├── loot_table.gd           # LootTable Resource class
│   ├── dungeon_data.gd         # DungeonData Resource class
│   ├── items/                  # .tres item definitions
│   │   ├── sword_01.tres
│   │   ├── bow.tres
│   │   └── ...
│   ├── enemies/                # .tres enemy stat definitions
│   │   ├── soldier.tres
│   │   └── ...
│   ├── dungeon_data/
│   │   └── dungeon_01.tres
│   └── loot_tables/
│       ├── bush_loot.tres
│       └── enemy_loot.tres
├── shaders/
│   ├── water.gdshader
│   ├── damage_flash.gdshader
│   ├── screen_transition.gdshader
│   ├── dark_world_palette.gdshader
│   └── lighting_overlay.gdshader
├── audio/                      # Empty dirs — drop .ogg/.wav here later
│   ├── bgm/
│   └── sfx/
└── debug/
    └── debug_room.tscn         # Test room with all entity types (not part of game world)
```

---

## Primitive Visual Language

Since there are no sprites, every entity uses a consistent shape+color system:

| Entity | Visual |
|---|---|
| Player (Link) | Green pentagon body + skin-colored circle head. Triangle "cap" rotates with facing direction. |
| Enemies | Colored polygons — red for aggressive, blue for passive, orange for ranged. Shape = type (circle=octorok, triangle=stalfos, diamond=keese). |
| Walls/Terrain | `TileMapLayer` colored rects. Greens/browns for overworld, grays for dungeon. |
| Water | Blue tiles with animated sine-wave shader. |
| Doors | Narrow gap in wall. Locked doors show a small yellow rectangle (keyhole). |
| Chests | Small yellow/brown rectangle with lighter lid. |
| Bushes/Pots | Small green circles (bushes), brown squares (pots). |
| Sword | White arc drawn via `_draw()` during attack. |
| Projectiles | Yellow triangle=arrow, gray circle=bomb, blue line=hookshot. |
| Hearts (HUD) | Red `Polygon2D` heart shape. |
| Rupees | Green diamond `Polygon2D`. |

---

## Phase 1: Core Foundation

**Milestone**: "Link Walks Around a Room"

### 1.1 Project Configuration

- Display: 256×224, stretch mode "viewport", aspect "keep", 4× window
- Input map (keyboard + gamepad):
  - `move_up/down/left/right` — WASD + arrows + left stick + d-pad
  - `action_sword` — J / X + gamepad B (east)
  - `action_item` — K / Z + gamepad Y (west)
  - `action_dash` — L / C + gamepad A (south)
  - `action_shield` — Shift + gamepad LB
  - `pause` — Escape / Enter + gamepad Start
  - `interact` — E / Space + gamepad X (north)
- Physics layers:

  | Layer | Name | Used By |
  |---|---|---|
  | 1 | World | Walls, terrain collision |
  | 2 | Player | Player CharacterBody2D |
  | 3 | Enemies | Enemy CharacterBody2D |
  | 4 | PlayerAttacks | Sword hitbox, player projectiles |
  | 5 | EnemyAttacks | Enemy projectiles, contact hitboxes |
  | 6 | Interactables | Chests, signs, pots, bushes, NPCs |
  | 7 | Hazards | Pits, spikes, lava |
  | 8 | Triggers | Room transitions, event zones |

- Register autoloads (load order matters): EventBus, GameManager, InventoryManager, AudioManager, SceneManager, SaveManager

### 1.2 Main Scene

**Scene** (`scenes/main/main.tscn`) — the project's main/entry scene:
- `Node` root ("Main")
  - `World` (Node2D) — SceneManager loads/swaps room scenes as children of this node
  - `TransitionOverlay` (`CanvasLayer`, layer 20) — `ColorRect` with transition shader, managed by SceneManager
  - `HUD` (`CanvasLayer`, layer 10) — the HUD scene instance
  - `DialogLayer` (`CanvasLayer`, layer 15) — dialog box instance
  - `PauseLayer` (`CanvasLayer`, layer 25) — inventory screen, `process_mode = ALWAYS`

This is the always-loaded root. SceneManager never replaces it — only swaps children under `World`. The title screen is also loaded under `World`.

### 1.3 Autoloads

**EventBus** — Pure signal hub for decoupled communication:
- `player_health_changed(current, max)`
- `player_magic_changed(current, max)`
- `player_rupees_changed(amount)`
- `player_damaged(amount, source)`
- `player_died`
- `enemy_defeated(enemy_type, position)`
- `item_acquired(item_id)`
- `room_transition_requested(target_room, entry_point)`
- `world_switch_requested(target_world)`
- `dialog_requested(text_lines)`
- `screen_shake_requested(intensity, duration)`

**GameManager** — Global game state: current world (light/dark), dungeon context, game flags dict (puzzle state, chest opened, boss defeated), pause state. Exposes `set_flag(key, value)` / `get_flag(key)`.

**SceneManager** — Room/scene transitions with shader-based iris/fade animation. Uses `ResourceLoader.load_threaded_request()` for async loading. Positions player at correct entry point. Maintains current room reference.

**AudioManager** — Skeleton placeholder. Two `AudioStreamPlayer` children for BGM crossfade (0.5s tween). Pool of 8 `AudioStreamPlayer` instances for SFX. All public methods (`play_bgm(track_name)`, `stop_bgm()`, `play_sfx(sfx_name)`, volume controls) check for a real audio file at `res://audio/bgm/{track_name}.ogg` or `res://audio/sfx/{sfx_name}.ogg` — if it exists, play it; otherwise print `[Audio] BGM: {track_name}`. Adding audio later = dropping files into the right folder.

**InventoryManager** — Equipped items (2 action slots), owned items dict, passive upgrade tiers (sword, armor, shield, gloves), rupees, per-dungeon keys/boss keys, heart pieces, current/max hearts, current/max magic. Methods: `add_item()`, `equip_item()`, `spend_rupees()`, `add_key()`, `use_key()`.

**SaveManager** — Serializes GameManager flags + InventoryManager state to `user://save_{slot}.json`. Phase 1 stub that prints to log.

### 1.4 Player Character

**Scene structure** (`player.tscn`):
- `CharacterBody2D` root
  - `CollisionShape2D` — ~12×14 px rectangle (fits 16px corridors)
  - `PlayerBody` (Node2D) — custom `_draw()` renders polygon based on facing
  - `SwordHitbox` (Area2D) — disabled by default, enabled during attacks
  - `ShieldArea` (Area2D) — positioned in facing direction, enabled while held
  - `HurtboxComponent` (Area2D) — always active
  - `HitboxComponent` (Area2D) — for sword/item damage
  - `StateMachine` (Node)
  - `AnimationPlayer` — squash/stretch, flash
  - `Camera2D` — follows player, limits per room
  - `DashDustSpawner` (GPUParticles2D)
  - `PointLight2D` — subtle warm glow

**Properties**: `facing_direction` (Vector2, 8-directional), `speed` (90 px/s), `push_speed` (30 px/s). Diagonal movement is normalized (magnitude clamped to 1.0) so diagonal speed equals cardinal speed.

**State Machine** (`components/state_machine.gd`) — generic reusable node. Dict of child State nodes, tracks `current_state`. Delegates `_physics_process` and `_unhandled_input` to active state. `transition_to(state_name)` calls `exit()` then `enter()`.

**Player States**:

| State | Behavior |
|---|---|
| Idle | No movement. → Walk on input, Attack on sword, ItemUse on item, Dash on dash (if boots). |
| Walk | 8-directional at `speed`. Interpolated velocity. → Idle on no input, Attack on sword. |
| Attack | Sword swing ~0.3s. `SwordHitbox` arc in facing direction. Immobile. Hold to charge → SpinAttack after 1.0s. |
| SpinAttack | 360° sweep, higher damage, costs magic. → Idle on completion. |
| Dash | 2.5× speed in facing direction, no steering. Dust particles. Wall collision → Knockback. ~1.5s duration. |
| ItemUse | Triggers equipped item's `activate()`. Duration varies by item. |
| Fall | Triggered by pit. Scale tween to 0, respawn at last safe position, 1 heart damage. |
| Knockback | Hit reaction. Move in knockback direction ~0.2s. 1.0s invincibility frames (flash/blink). → Idle. |

**Input buffering**: The last action input (sword, item, dash) is stored for ~0.1s. If the player presses sword during the last frames of a walk step, the attack triggers as soon as the current state allows a transition. This prevents inputs from being swallowed.

**States added in later phases** (not implemented in Phase 1):
- `SwimState` — Phase 8 (Flippers)
- `LiftState` / `CarryState` / `ThrowState` — Phase 8 (Gloves)

### 1.5 Camera System

`Camera2D` on Player node:
- **Overworld**: Limits set to room boundaries. Room edge crossing → 0.5s scroll tween + player auto-walk. Smooth follow (`position_smoothing_speed = 8.0`).
- **Dungeons**: Snap to room boundaries, instant fade transitions.

### 1.6 Base Room Structure

**Scene** (`room.tscn`):
- `Node2D` root
  - `TileMapLayer` ("Terrain") — ground, walls, water. Uses a shared `TileSet` resource (`.tres`) with a single atlas source: a small PNG texture grid of colored 16×16 squares (e.g., 8×4 = 32 tile variants). Physics collision layers baked into wall/hazard tiles.
  - `TileMapLayer` ("Overlay") — above-player decoration (y-sort layer above player).
  - `Entities` (Node2D, **`y_sort_enabled = true`**) — enemies, NPCs, interactables, **and the player**. Y-sort ensures entities lower on screen draw in front of entities higher up, matching ALTTP's visual depth.
  - `Transitions` (Node2D) — Area2D triggers at room edges/doors.
  - `NavigationRegion2D` — baked navigation mesh for enemy pathfinding. Generated from terrain (walkable tiles = navigable). Required for `NavigationAgent2D` to work.
  - `CanvasModulate` — ambient lighting.
  - `PointLight2D` nodes — atmospheric.

**TileSet**: A single shared `.tres` resource used by all rooms. The atlas source is a minimal PNG grid of colored squares — no hand-painted art. Each tile ID maps to a tile type via custom data layers on the TileSet (e.g., `tile_type: "floor"`, `tile_type: "wall"`). Auto-terrain rules can be set up for wall/floor boundaries.

**Tile types**: Floor (walkable), Wall (collision), Water (shader, damages without flippers), Pit (triggers fall), Ledge (one-way: `one_way_collision` enabled), Conveyor (applies velocity via custom data), Ice (reduced friction via custom data).

**Room loading strategy**: SceneManager manages the `World` node in `main.tscn`. For **dungeon transitions**: fade out, remove current room, instantiate new room, add to `World`, fade in. For **overworld scroll transitions**: both current and adjacent rooms must be loaded simultaneously (adjacent room instantiated offset by one screen width/height), camera tweens across, then the old room is freed. SceneManager preloads the 4 cardinal neighbor rooms of the current screen using `ResourceLoader.load_threaded_request()`.

**Room persistence**: Enemies respawn every time a room is re-entered (matches ALTTP behavior). Persistent state (opened chests, moved push blocks, toggled switches) is tracked via `GameManager.set_flag()` — rooms check these flags in `_ready()` to restore solved puzzle state.

### 1.7 Phase 1 Deliverable

Single overworld room (~16×11 tiles). Player walks 8 directions, swings sword (visible arc), takes damage from test hazard, hearts on HUD. Camera stays in bounds. Console logs audio events.

---

## Phase 2: Combat System

**Milestone**: "Link Fights Enemies"

### 2.1 Hitbox/Hurtbox Components

**HurtboxComponent** (Area2D): Detects incoming hits. `invincible` flag. Emits `hurt(hitbox)` with damage, knockback direction, effect type. Manages invincibility timer.

**HitboxComponent** (Area2D): Deals damage. Properties: `damage`, `knockback_force`, `effect` (NONE/STUN/FREEZE/BURN).

**KnockbackComponent**: Applies decelerating knockback velocity for short duration.

**FlashComponent**: White flash shader (`flash_intensity` uniform tweened 1.0→0.0 over 0.1s).

### 2.2 Enemy Data Resource

```gdscript
class_name EnemyData extends Resource

@export var id: StringName
@export var display_name: String
@export var max_health: int
@export var contact_damage: int
@export var knockback_resistance: float  # 0.0 = full knockback, 1.0 = immune
@export var speed: float
@export var detection_radius: float
@export var attack_range: float
@export var drop_table: LootTable
@export var color: Color                 # Primary shape color
@export var immunities: Array[StringName] # e.g., ["sword", "fire"]
```

Each enemy type has a `.tres` instance. The `base_enemy.gd` script loads its data from an exported `EnemyData` resource, keeping stats separate from behavior.

### 2.3 Enemy Base

**Scene** (`base_enemy.tscn`):
- `CharacterBody2D` root
  - `EnemyBody` (Node2D, `_draw()`)
  - `CollisionShape2D`
  - `HurtboxComponent`, `HitboxComponent`, `HealthComponent`
  - `KnockbackComponent`, `FlashComponent`, `LootDropComponent`
  - `StateMachine`
  - `NavigationAgent2D` (pathfinding)
  - `DetectionZone` (Area2D, player detection radius)

On health=0: death particles + scale-to-zero tween, loot drop, `EventBus.enemy_defeated`, `queue_free()`.

**Enemy States**:

| State | Behavior |
|---|---|
| Patrol | Random walk / fixed path / stationary. → Chase on player detection. |
| Chase | Move toward player (NavigationAgent2D or vector pursuit). → Attack in range. → Patrol if player escapes. |
| Attack | Contact, projectile, or lunge. Cooldown → Chase. |
| Stunned | Boomerang/stun hit. Immobile X seconds, blue tint flash. |

### 2.4 Enemy Types (Initial Set)

| Enemy | Shape | Behavior |
|---|---|---|
| Soldier | Red rectangle + triangle helmet | Patrols, chases, sword lunge |
| Octorok | Red circle | Slow patrol, shoots 4-directional projectiles |
| Keese | Purple diamond, flutter | Erratic sine-wave flight, contact only |
| Stalfos | White triangle | Random walk, throws bone projectiles |
| Buzz Blob | Yellow circle, pulsing shader | Random walk, contact damage, sword-immune |

### 2.5 Projectile System

`projectile_base.tscn` — `Area2D` with visual, collision, lifetime timer. Properties: `speed`, `damage`, `direction`, `lifetime`, `pierce`. Wall hit → destroy. Hurtbox hit → damage + (optionally) destroy. Subclasses override (boomerang returns, hookshot retracts, bomb explodes).

### 2.6 Loot Drops

**LootTable** (custom Resource): Array of `{item_id, weight, quantity_min, quantity_max}`. `roll()` → weighted random.

**LootDropComponent**: Rolls table, spawns pickup at position. Pickups bob (tween) and collect on player overlap.

Pickup types: Heart (+1), Rupee (green=1, blue=5, red=20), Magic jar, Arrows, Bombs.

### 2.7 Phase 2 Deliverable

Room with 3–4 enemy types. Combat, drops, knockback, i-frames all functional. Sword arc + collision. Kill effects with particles.

---

## Phase 3: Items & Inventory

**Milestone**: "Link Has Equipment"

### 3.1 Item Data Resource

```gdscript
class_name ItemData extends Resource

@export var id: StringName
@export var display_name: String
@export var description: String
@export var item_type: ItemType        # ACTIVE, PASSIVE, COLLECTIBLE
@export var icon_color: Color
@export var icon_shape: PackedVector2Array
@export var magic_cost: float
@export var ammo_type: StringName      # "arrows", "bombs", ""
@export var ammo_cost: int
@export var tier: int
@export var use_script: Script         # Script with activate() method
```

### 3.2 Active Items

Each extends `BaseActiveItem`. `activate(player, direction)` called from `ItemUseState`.

| Item | Mechanic |
|---|---|
| Bow | Arrow projectile in facing direction. 1 arrow ammo. |
| Bombs | Place bomb at position. 2.5s fuse → explosion (Area2D damage, screen shake, particles). Destroys cracked walls. 1 bomb ammo. |
| Boomerang | Travels ~5 tiles, curves back. Stuns enemies, collects pickups. Magic variant: full screen range. |
| Hookshot | Chain extends in facing direction. Hookable target → pull player. Enemy → stun. Wall → retract. Rendered via `_draw()`. |
| Lamp | Temporary `PointLight2D` ahead of player. Lights dark rooms, ignites torches. Costs magic. |
| Magic Powder | Sprinkle effect, transforms certain enemies. Costs magic. |
| Fire Rod | Fire projectile with red/orange particle trail. Lights torches at range. Costs magic. |
| Ice Rod | Ice projectile with blue trail. Freezes enemies. Costs magic. |
| Hammer | Melee, pounds pegs (puzzle element), flips enemies. Short range, slow. |

### 3.3 Passive Upgrades

| Upgrade | Tiers | Effect |
|---|---|---|
| Sword | 1–4 | Damage increase, wider/brighter arc |
| Armor | 1–3 (Green/Blue/Red) | Damage reduction |
| Shield | 1–3 | Blocks more projectile types, color changes (see shield mechanics below) |
| Gloves | 1–2 (Power/Titan's Mitt) | Lift light/heavy objects |
| Flippers | Boolean | Swim in water instead of taking damage |
| Pegasus Boots | Boolean | Enables dash |
| Moon Pearl | Boolean | Prevents Dark World transformation |

### 3.4 Shield Mechanics

The shield is **passive/automatic** (matches ALTTP): when the player is idle or walking and a projectile hits the `ShieldArea` (positioned in `facing_direction`), the projectile is deflected. No button hold required for basic blocking. Holding `action_shield` raises the shield in all directions (wider block arc, slower movement).

| Tier | Blocks |
|---|---|
| 1 (Fighter's) | Rocks, arrows |
| 2 (Fire) | + fireballs, beams |
| 3 (Mirror) | + magic projectiles, reflects some attacks back |

Deflected projectiles either vanish (tier 1–2) or bounce back toward the source (tier 3 Mirror Shield). Shield is an `Area2D` that checks incoming hitboxes for a `projectile_class` property to decide if it can block.

### 3.5 Inventory Screen

Full-screen overlay on `pause`. `get_tree().paused = true`, screen `process_mode = ALWAYS`.

- Top: Equipped slot (highlighted) + grid of owned active items (4 columns, d-pad selectable)
- Middle: Passive equipment display (sword/armor/shield tiers as colored shapes)
- Bottom: Collectible status (heart pieces ×/4, dungeon map/compass/big key)
- Cursor: Yellow rectangle outline
- Items drawn as their `icon_shape` in `icon_color`

### 3.6 Phase 3 Deliverable

Inventory screen, equip items, use bow/bombs/boomerang. Ammo/magic consumption. Passive upgrades affect gameplay. 4+ active items functional.

---

## Phase 4: World Structure & Transitions

**Milestone**: "Explorable Overworld"

### 4.1 Overworld Grid

Screens = 256×224 px each, named `overworld_X_Y.tscn`. SceneManager tracks `current_screen_coords: Vector2i`.

**Room edge crossing**:
1. Determine new coords
2. Disable input, camera scroll tween (0.5s), player auto-walks into new screen
3. Load adjacent room (preload neighbors)
4. Update camera limits, re-enable input

Initial overworld: 4×4 grid (16 screens). Distinct areas via tile colors — forest (dark green), field (light green), mountain (gray), lake (blue).

### 4.2 Interior/Cave Transitions

`Door` scene: Area2D trigger → on `interact` or walk-in, initiates transition. Properties: `target_scene`, `target_entry_point` (Marker2D name in target).

**Iris transition shader**: `ColorRect` on `CanvasLayer`, circle mask uniform animated. Iris-out from player position → load → iris-in.

### 4.3 Dungeon Structure

**DungeonData Resource**:
```gdscript
@export var dungeon_id: StringName
@export var dungeon_name: String
@export var rooms: Dictionary          # Vector2i → PackedScene
@export var starting_room: Vector2i
@export var boss_room: Vector2i
@export var small_key_count: int
@export var boss_id: StringName
```

Dungeon rooms: quick fade transitions (not scroll). Per-dungeon tracking: small keys, big key, map, compass.

**Dungeon elements**:
- **LockedDoor**: 1 small key to open. Collision disabled + visual change.
- **BossDoor**: Big key required. Larger, different color.
- **Chest**: `interact` to open. Contains item/key/map/compass/rupees. State tracked via GameManager flag.
- **PushBlock**: Player pushes 1 tile. Can activate switches. Persistent state in GameManager.
- **Switch**: Toggled by sword/arrow/thrown object. Linked to doors/bridges via exported NodePath.
- **PressurePlate**: Activated by player or push block weight. Toggles linked elements.
- **Pit**: Triggers FallState. In dungeons, may drop to lower floor.
- **ConveyorBelt**: Applies constant velocity. Animated arrow pattern shader.

### 4.4 Light World / Dark World

Two parallel overworlds, same grid dimensions, different scenes.

Dark World visual distinction:
- `CanvasModulate` — darker, purple tint
- Different tile colors (reds, purples, dark browns)
- Screen-wide palette-shift shader on `CanvasLayer`
- Tougher enemy variants

**Magic Mirror** (world switching):
1. Use in Dark World → swirl transition shader
2. Player placed at same coords in Light World
3. Sparkle portal left at landing spot → walk in to return

Without Moon Pearl: entering Dark World transforms player (different shape, limited actions).

### 4.5 Phase 4 Deliverable

4×4 overworld with screen scrolling. 2+ cave entrances. One 4-room dungeon with locked door, key, push block puzzle, chest. Iris transitions. Light/Dark world switching (2×2 dark world minimum).

---

## Phase 5: Bosses & Advanced Combat

**Milestone**: "First Dungeon Complete"

### 5.1 Boss Base System

Extends enemy system with:
- `phase: int` — behavior changes at health thresholds
- `HealthBar` — `Control` node drawn at top of screen
- Phase transitions with immunity frames + particle flourish
- Camera lock to boss room boundaries
- Boss door closes behind player on entry

### 5.2 Armos Knights (Dungeon 1 Boss)

Boss controller managing 6 `CharacterBody2D` knights.

**Phase 1** (6 alive): Synchronized hop pattern, occasionally target player. Contact damage. Individual health. Remaining knights speed up as others die.

**Phase 2** (1 remaining): Turns red (shader), faster, jump-attacks player position (shadow indicator before landing).

Defeat → heart container drop + warp tile.

### 5.3 Dungeon Completion

On boss defeat:
- Heart Container pickup (golden, larger than normal hearts). +1 max heart, full heal.
- Warp tile appears (blue glow Area2D) → teleports to dungeon entrance.
- `GameManager.set_flag("dungeon_01_complete", true)`

### 5.4 Phase 5 Deliverable

One fully playable dungeon: entrance, 4–6 rooms, puzzles, enemies, keys, boss with 2 phases, heart container reward.

---

## Phase 6: HUD, UI & Polish

**Milestone**: "Feels Like a Game"

### 6.1 HUD

`CanvasLayer` (layer 10). Top of screen, ~24px bar, semi-transparent dark background.

- **Hearts** (top-left): `_draw()` — full=red, half=half-filled, empty=dark outline. Max 20. Listens to `EventBus.player_health_changed`.
- **Magic Meter** (left, below hearts): Vertical bar, green fill, dark border.
- **Rupees** (top-center-left): Green diamond polygon + monospace label.
- **Equipped Item** (top-right): Box outline + item's `icon_shape` in `icon_color`.
- **Minimap** (top-right, dungeon only): Grid of small rectangles. Current=highlighted, visited=dimmed, unvisited=hidden (unless map collected).
- **Key Count** (dungeon only): Key icon + number.

### 6.2 Dialog System

`CanvasLayer` dialog box at bottom of screen. Dark fill, light border drawn via `_draw()`. `RichTextLabel` with typewriter effect (`visible_characters` + Timer). `interact` speeds up or advances. Supports sequential text lines.

Triggered via `EventBus.dialog_requested(lines)`.

### 6.3 Shader Effects

| Shader | Effect |
|---|---|
| `screen_transition.gdshader` | Iris-in/out circle mask. `center`, `progress`, `color` uniforms. |
| `damage_flash.gdshader` | Mix toward white. `flash_amount` uniform 0→1. |
| `water.gdshader` | Sine-wave UV distortion + blue color cycling. |
| `dark_world_palette.gdshader` | Palette shift toward cooler/darker tones. |

### 6.4 Visual Effects & Juice

- **Screen shake**: `Camera2D.offset` jitter via tween. Triggered by `EventBus.screen_shake_requested`.
- **Squash & stretch**: Player body scales on swing (1.2× wide, 0.8× tall) and landing. `AnimationPlayer` tracks on `PlayerBody.scale`.
- **Impact particles**: White sparks on sword hits, colored triangles on enemy death, orange/red on explosions.
- **Dash dust**: Brown circles fading out behind player.
- **Environmental particles**: Floating dust motes in dungeons, leaf particles in forests.
- **Lighting**: `CanvasModulate` per room. Player `PointLight2D`. Torch `PointLight2D` with flicker (random energy). Dark rooms near-black until Lantern/torches lit.

### 6.5 Title Screen

`Label` nodes for title (built-in font, large). Menu: New Game / Continue / Options. Background: animated color gradient shader. Start → SceneManager loads overworld.

### 6.6 Phase 6 Deliverable

Full HUD, dialog system, shader transitions, particles on all combat, title screen. Polished feel despite primitive art.

---

## Phase 7: Expanded Content

**Milestone**: "Full Game Loop"

### 7.1 Additional Dungeons

- **Dungeon 2**: Conveyor belts, pit-heavy rooms. Projectile-pattern boss.
- **Dungeon 3**: Dark rooms (Lantern required), moving platforms. 3-phase boss.

Each: entrance, 6–10 rooms, map/compass/big key, 2–4 small keys, unique boss, heart container.

### 7.2 Heart Pieces

4 pieces = 1 heart container. Found via:
- Mini-puzzles (bomb cracked wall, push block → reveal stairs)
- NPC conversations
- Hidden chests in optional caves
- Mini-games (future: digging, chest game)

### 7.3 NPC System

`StaticBody2D` (or `CharacterBody2D` for wandering). Visual via `_draw()`. `InteractArea` (Area2D) triggers dialog. `dialog_lines` export. Optional `required_flag` — only visible if GameManager flag set.

### 7.4 Destructible Objects

Bushes, pots, skulls: `StaticBody2D` with collision. Sword/dash → destroy + particles + loot roll. With Gloves → pick up, carry overhead, throw as projectile.

### 7.5 Expanded Overworld

4×4 → 8×8. Biomes: field (light green), forest (dark green), mountain (gray), desert (tan), lake (blue, needs Flippers), village (NPCs, buildings), graveyard.

### 7.6 Save/Load

Serialize: player overworld coords + offset, InventoryManager state, GameManager flags. 3 slots. Save at: save points (beds/statues), game over screen. Load from title screen.

### 7.7 Phase 7 Deliverable

3 completable dungeons, populated overworld, NPCs, heart pieces, save/load, destructibles, expanded map.

---

## Phase 8: Advanced Mechanics

**Milestone**: "Feature Complete"

### 8.1 Swimming

With Flippers: water → Swim state. 60% speed, smaller scale, ripple particles. Without: damage hazard, pushes back.

### 8.2 Lifting & Throwing

With Gloves: `interact` facing liftable → Lift state. Object becomes child of player. Throw with action button → projectile, shatters on impact. Power Glove = light objects. Titan's Mitt = heavy.

### 8.3 Magic System

Max 128 units. Costs: Spin attack 25%, Lantern 4u, Fire/Ice Rod 8u, Magic Powder 4u, Medallions 50%. Refill: Magic Jar pickups (small=16u, large=full). Half Magic upgrade halves all costs.

### 8.4 Game Over

Health=0 → death animation (spin, shrink, red flash) → fade to black → "Game Over" screen (Continue / Save and Quit). Continue: respawn at dungeon entrance or overworld start, 3 hearts restored.

### 8.5 Advanced Enemies

| Enemy | Behavior |
|---|---|
| Wizzrobe | Teleport → telegraph → fire magic → disappear → reappear elsewhere |
| Like-Like | Slow pursuit, engulfs on contact (mash to escape), can eat shield |
| Moldorm | Multi-segment chain of circles, only tail vulnerable, erratic movement, speeds up |

### 8.6 Audio Hookup Points

Every AudioManager call is already in place, logging to console. Full coverage:

- **BGM**: Each biome, each dungeon, boss rooms, title screen, game over, inventory, dark world, caves
- **SFX**: Sword swing/hit, shield block, item pickups, chest open, door unlock, bomb place/explode, arrow fire, hookshot, player hurt/death, enemy hurt/death, menu cursor/select, text blip, dash, push block, switch toggle, fall, transitions

Adding real audio = place `.ogg`/`.wav` at `res://audio/sfx/{name}.ogg` or `res://audio/bgm/{name}.ogg`.

### 8.7 Phase 8 Deliverable

Swimming, lifting/throwing, full magic system, game over flow, 3 advanced enemy types, all audio hooks documented. Feature-complete ALTTP mechanics recreation.

---

## Architecture Reference

### Signal Flow: Player Takes Damage

```
Enemy HitboxComponent overlaps Player HurtboxComponent
  → HurtboxComponent emits hurt(hitbox)
  → player._on_hurtbox_hurt(hitbox)
     → Calculate damage (base - armor reduction)
     → HealthComponent.take_damage(final_damage)
        → EventBus.player_health_changed → HUD updates
        → If health ≤ 0: EventBus.player_died → GameManager game over
     → FlashComponent.flash()
     → KnockbackComponent.apply(direction, force)
     → StateMachine.transition_to("Knockback")
     → HurtboxComponent starts invincibility timer
     → AudioManager.play_sfx("player_hurt")
     → EventBus.screen_shake_requested(0.5, 0.15)
```

### State Base Class

```gdscript
class_name State extends Node

var state_machine: StateMachine
var actor: CharacterBody2D  # Set by StateMachine._ready()

func enter() -> void: pass
func exit() -> void: pass
func handle_input(_event: InputEvent) -> void: pass
func physics_update(_delta: float) -> void: pass
```

All player states extend `PlayerState` (which extends `State` and types `actor` as `Player`). All enemy states extend `EnemyState` (types `actor` as `BaseEnemy`).

### State Machine Pattern

```gdscript
class_name StateMachine extends Node

@export var initial_state: State
var current_state: State
var states: Dictionary = {}

func _ready():
    var parent = get_parent()
    for child in get_children():
        if child is State:
            states[child.name.to_lower()] = child
            child.state_machine = self
            child.actor = parent  # Give each state a reference to the owning entity
    current_state = initial_state
    current_state.enter()

func _physics_process(delta):
    current_state.physics_update(delta)

func _unhandled_input(event):
    current_state.handle_input(event)

func transition_to(state_name: String):
    if current_state:
        current_state.exit()
    current_state = states[state_name]
    current_state.enter()
```

### Item Resource Pattern

```gdscript
# resources/items/bow.tres
[gd_resource type="Resource" script_class="ItemData"]
[resource]
id = &"bow"
display_name = "Bow"
item_type = 0  # ACTIVE
icon_color = Color(0.6, 0.4, 0.2)
magic_cost = 0
ammo_type = &"arrows"
ammo_cost = 1
```

### Collision Masks

| Entity | Layer (is on) | Mask (scans) |
|---|---|---|
| Player body | 2 | 1, 7 |
| Player hurtbox | 2 | 5 |
| Player hitbox (sword) | 4 | 3, 6 |
| Player shield | 2 | 5 |
| Enemy body | 3 | 1, 3 |
| Enemy hurtbox | 3 | 4 |
| Enemy hitbox | 5 | — |
| Player projectiles | 4 | 1, 3, 6 |
| Enemy projectiles | 5 | 1, 2 |
| Pickups | 6 | 2 |
| Triggers | 8 | 2 |

---

## Implementation Priority

| Phase | Milestone | Key Systems |
|---|---|---|
| 1 | Link Walks Around a Room | Movement, camera, room, HUD stub, autoloads |
| 2 | Link Fights Enemies | Combat, hitbox/hurtbox, 5 enemies, drops |
| 3 | Link Has Equipment | Items, inventory screen, 4+ usable items |
| 4 | Explorable Overworld | Screen transitions, dungeons, world switching |
| 5 | First Dungeon Complete | Boss system, full dungeon playthrough |
| 6 | Feels Like a Game | Full HUD, dialog, shaders, particles, title screen |
| 7 | Full Game Loop | 3 dungeons, expanded world, NPCs, save/load |
| 8 | Feature Complete | Swimming, lifting, magic, game over, advanced enemies |

Each phase builds on the prior. No phase requires throwing away previous work. Architecture supports adding content (enemies, rooms, items) without modifying core systems.

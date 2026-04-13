# SPEC.md

## Title

Mega Man X (1993) Mechanics-First Remake in Godot 4.6

## Summary

This project will recreate the feel, control, combat, and progression structure of *Mega Man X* (1993) in Godot 4.6 as a 2D side-scrolling action platformer. The remake is mechanics-first, not pixel-perfect. The priority is to reproduce responsive movement, combat pacing, stage flow, enemy and boss interactions, and progression beats while using a modern, maintainable Godot architecture.

The project will begin and remain placeholder-first until production assets exist. Placeholder visuals, animation hooks, VFX hooks, SFX, and music placeholders must be supported from day one. Core gameplay logic must never depend on final sprite sheets, final sound files, or specific presentation assets.

This document is an implementation spec. It defines scope, architecture, feature requirements, stable gameplay contracts, milestone boundaries, and acceptance criteria so future implementation work can proceed without making new product decisions.

## Scope Of The Full Remake

The target is the original single-player campaign:

- `intro_highway`
- the 8 Maverick stages
- Sigma Fortress stages
- final Sigma fights
- boss weapons
- armor parts
- heart tanks
- sub tanks

## Core Class Layout

This section replaces broad architecture talk with the actual class and scene shape the project should use.

### Shared actor inheritance

Inheritance stays shallow:

- `ActorBase.gd` for health, team, hurtbox hookup, death flow
- `EnemyBase.gd` extends `ActorBase.gd`
- `BossBase.gd` extends `ActorBase.gd`
- `Player.gd` extends `CharacterBody2D` directly and owns player-specific movement and input

```gdscript
class_name ActorBase
extends CharacterBody2D

signal died(actor_id: StringName)

@export var actor_id: StringName
@export var team: StringName
@export var max_health := 1

var health := 0

@onready var hurtbox: Hurtbox = $Hurtbox

func _ready() -> void:
    health = max_health
    hurtbox.hit_received.connect(_on_hit_received)

func _on_hit_received(hit: HitData) -> void:
    health -= hit.damage
    if health <= 0:
        died.emit(actor_id)
        queue_free()
```

```gdscript
class_name EnemyBase
extends ActorBase

@onready var brain: EnemyBrain = $EnemyBrain
@onready var drop_spawner: Node = $DropSpawner

func _physics_process(delta: float) -> void:
    brain.physics_update(delta)
```

```gdscript
class_name BossBase
extends ActorBase

signal boss_defeated(boss_id: StringName)

@onready var phase_controller: BossPhaseController = $BossPhaseController

func _on_hit_received(hit: HitData) -> void:
    super._on_hit_received(hit)
    phase_controller.update_phase(_health_percent())
    if health <= 0:
        boss_defeated.emit(actor_id)
```

### Composition in actual scenes

Composition happens in scene trees, not in prose:

```text
Player.tscn
- Player (CharacterBody2D) [Player.gd]
  - CollisionShape2D
  - VisualRoot
  - Hurtbox [Hurtbox.gd]
  - PlayerCombat [PlayerCombat.gd]
  - ShotOrigin
  - WallCheckLeft
  - WallCheckRight
  - CameraAnchor
```

```text
Enemy_WalkerBasic.tscn
- EnemyWalkerBasic (CharacterBody2D) [EnemyBase.gd]
  - CollisionShape2D
  - VisualRoot
  - Hurtbox [Hurtbox.gd]
  - EnemyBrain [EnemyBrain.gd]
  - DropSpawner [DropSpawner.gd]
  - VisionArea
  - AttackOrigin
```

```text
Boss_ChillPenguin.tscn
- BossChillPenguin (CharacterBody2D) [BossBase.gd]
  - CollisionShape2D
  - VisualRoot
  - Hurtbox [Hurtbox.gd]
  - BossPhaseController [BossPhaseController.gd]
  - AttackOrigin
  - IntroMarker
  - ArenaMarker
```

### Core data resources

Use `Resource` files for authored data that should not live inside controller scripts:

```gdscript
class_name PlayerTuning
extends Resource

@export var run_speed: float = 220.0
@export var jump_velocity: float = -360.0
@export var dash_speed: float = 340.0
@export var dash_duration: float = 0.18
@export var wall_slide_speed: float = 70.0
```

```gdscript
class_name StageDefinition
extends Resource

@export var stage_id: StringName
@export var display_name: String
@export var stage_scene: PackedScene
@export var boss_id: StringName
@export var weapon_reward_id: StringName
```

## Runtime Services And Interaction Model

This project should use a small, explicit set of autoloads. Do not add a generic global event bus.

### Autoload scripts

- `autoloads/game_flow.gd`
- `autoloads/progression.gd`
- `autoloads/save_manager.gd`
- `autoloads/audio_manager.gd`

### Autoload responsibilities

#### `GameFlow`

Owns high-level runtime state and scene transitions.

- Boot sequence.
- Title flow.
- Intro stage start.
- Stage select entry and exit.
- In-stage state.
- Pause and unpause flow.
- Cutscene mode entry and exit.
- Stage clear flow.
- Ending flow.

Suggested runtime states:

- `BOOT`
- `TITLE`
- `STAGE_SELECT`
- `IN_STAGE`
- `PAUSED`
- `CUTSCENE`
- `STAGE_CLEAR`
- `ENDING`

```gdscript
extends Node

enum GameState {
    BOOT,
    TITLE,
    STAGE_SELECT,
    IN_STAGE,
    PAUSED,
    CUTSCENE,
    STAGE_CLEAR,
    ENDING,
}

signal game_state_changed(previous: int, current: int)
signal stage_requested(stage_id: StringName)

var current_state := GameState.BOOT
var current_stage_id: StringName

func request_stage_load(stage_id: StringName) -> void:
    current_stage_id = stage_id
    stage_requested.emit(stage_id)
```

#### `Progression`

Owns in-memory campaign state.

- Which stages are unlocked.
- Which bosses are defeated.
- Which weapons are unlocked.
- Which persistent pickups are collected.
- Which armor parts are unlocked.
- Whether dash is unlocked in campaign progression.
- Which fortress or ending progression flags are active.

```gdscript
extends Node

signal progression_changed()

var bosses_defeated: Dictionary = {}
var weapons_unlocked: Dictionary = {}
var collected_pickups: Dictionary = {}
var armor_parts: Dictionary = {
    &"helmet": false,
    &"body": false,
    &"arms": false,
    &"legs": false,
}
var dash_unlocked := false
```

#### `SaveManager`

Owns serialization and deserialization only.

- Read save files from `user://`.
- Write versioned save payloads.
- Convert `Progression` runtime state to a serializable payload.
- Validate or migrate save version if needed later.

`SaveManager` should not own gameplay rules. It only persists and restores state.

#### `AudioManager`

Owns audio buses, event-to-stream lookup, one-shot SFX playback, music playback, and volume categories.

### Script interaction rules

Scripts should interact through three mechanisms only:

- Direct node references for tightly related scene-local collaborators.
- Signals for upward or sideways scene communication.
- Autoload method calls for global services like flow, progression, save, and audio.

Do not use:

- Arbitrary tree-walking from unrelated scripts.
- Generic string-based global event buses.
- Cross-system hard references when a signal or autoload boundary is cleaner.

### Example interaction flow

When a boss is defeated:

1. `BossBase.gd` emits `boss_defeated(boss_id)`.
2. `StageController.gd` receives the signal.
3. `StageController.gd` calls `Progression.mark_boss_defeated(boss_id)`.
4. `StageController.gd` calls `GameFlow.enter_stage_clear(stage_id)`.
5. `AudioManager` plays `boss_defeat` and then `stage_clear`.
6. The UI and stage-clear scene read from `Progression` to show rewards.

Example:

```gdscript
func _on_boss_defeated(boss_id: StringName) -> void:
    Progression.mark_boss_defeated(boss_id)
    Progression.unlock_weapon(_stage_data.weapon_reward_id)
    AudioManager.play_sfx(&"boss_defeat")
    GameFlow.enter_stage_clear(_stage_data.stage_id)
```

## Recommended Project Structure

The implementation should grow toward a structure similar to this:

- `scenes/`
- `scripts/`
- `data/`
- `ui/`
- `assets/placeholders/`
- `audio/`
- `autoloads/`
- `tests/` if automated testing is added

Suggested internal grouping:

- `scenes/player`, `scenes/enemies`, `scenes/bosses`, `scenes/stages`, `scenes/ui`
- `scripts/components`, `scripts/systems`, `scripts/resources`, `scripts/state`
- `data/player`, `data/weapons`, `data/enemies`, `data/bosses`, `data/stages`

Exact folder names can evolve, but scene, script, UI, data, and placeholder assets should remain clearly separated.

## Campaign Roster

The remake should target the original Mega Man X campaign structure with these primary boss IDs and stage IDs.

### Stage and boss roster

- `intro_highway` with scripted `vile_ride_armor` encounter and Zero rescue sequence
- `chill_penguin` with boss `chill_penguin`
- `spark_mandrill` with boss `spark_mandrill`
- `armored_armadillo` with boss `armored_armadillo`
- `launch_octopus` with boss `launch_octopus`
- `boomer_kuwanger` with boss `boomer_kuwanger`
- `sting_chameleon` with boss `sting_chameleon`
- `storm_eagle` with boss `storm_eagle`
- `flame_mammoth` with boss `flame_mammoth`
- `sigma_fortress_1` with boss `bospider`
- `sigma_fortress_2` with boss `rangda_bangda`
- `sigma_fortress_3` with boss `velguarder`
- `sigma_fortress_4` with bosses `sigma_first_form` and `sigma_wolf_form`

### Weapon reward IDs

- `shotgun_ice`
- `electric_spark`
- `rolling_shield`
- `homing_torpedo`
- `boomerang_cutter`
- `chameleon_sting`
- `storm_tornado`
- `fire_wave`

### Enemy naming approach

Boss names should match the original game. Regular enemies should be implemented as reusable families with stable internal IDs such as:

- `walker_basic`
- `turret_basic`
- `hopper_basic`
- `flying_drone_basic`
- `shield_guard_basic`
- `mine_dropper_basic`

If exact original enemy-name parity is important later, it should be added in a dedicated content roster document without changing the enemy framework architecture.

## Stage Scene Layout And Pickup Placement

Each playable stage should follow a predictable scene layout.

### Recommended stage composition

```text
Stage_FlameMammoth.tscn
- StageController (Node)
  - TilemapRoot
  - BackgroundRoot
  - SpawnPoints
  - Checkpoints
  - Enemies
  - Pickups
  - Capsules
  - Triggers
  - CameraZones
  - HazardZones
  - BossArena
  - MusicAnchor optional
```

### Where pickups live

Pickups and powerups belong in stage scenes, not in global managers.

- Temporary drops from defeated enemies are spawned at runtime by a `DropSpawner` component or by enemy death logic using a drop table resource.
- Persistent pickups are authored directly under the stage's `Pickups` or `Capsules` node.
- Persistent pickups must have unique IDs so collected items do not respawn after save/load.

### Pickup categories

- Temporary health pickups.
- Temporary weapon-energy pickups.
- Persistent heart tanks.
- Persistent sub tanks.
- Persistent armor capsules.
- Optional one-off scripted rewards tied to cutscenes or boss defeat flow.

### Pickup implementation direction

Use dedicated pickup scenes in `scenes/pickups/` with shared data resources in `data/pickups/`.

```gdscript
class_name PickupData
extends Resource

@export var pickup_id: StringName
@export var pickup_type: StringName
@export var persistent := false
@export var health_amount := 0
@export var weapon_energy_amount := 0
@export var armor_part: StringName
```

```gdscript
extends Area2D

@export var pickup_data: PickupData

func collect(player: Node) -> void:
    player.apply_pickup(pickup_data)

    if pickup_data.persistent:
        Progression.mark_pickup_collected(pickup_data.pickup_id)

    queue_free()
```

### Persistent pickup rules

- Heart tanks, sub tanks, and armor capsules are persistent.
- Small health and weapon refills are not persistent.
- Persistent pickups must be keyed by a stable ID such as `flame_mammoth_heart_tank` or `intro_highway_dash_capsule`.
- Stage load must query `Progression` and omit already-collected persistent pickups.

## Implementation Sketches

The following examples are not final production code. They are reference sketches that show the intended direction for the architecture and the level of separation expected between systems.

### Example player scene composition

The player should be composed from focused child nodes instead of one script owning every responsibility.

```text
Player.tscn
- Player (CharacterBody2D)
  - CollisionShape2D
  - VisualRoot (Node2D)
    - PlaceholderSprite or AnimatedSprite2D
  - Hurtbox (Area2D)
    - CollisionShape2D
  - ShotOrigin (Marker2D)
  - WallCheckLeft (RayCast2D)
  - WallCheckRight (RayCast2D)
  - GroundCheck optional if needed
  - CameraAnchor (Marker2D)
```

Recommended script ownership:

- `Player.gd` owns locomotion state, motion integration, and high-level action routing.
- `PlayerCombat.gd` or a child combat component owns weapon firing, charge timing, and projectile spawning.
- `Hurtbox.gd` receives hit events and forwards valid damage to the player health or state system.
- A presentation script owns animation-state switching and visual-only reactions.

### Example data-driven tuning resource

Player tuning should live in a `Resource` so feel iteration does not require editing controller logic.

```gdscript
class_name PlayerTuning
extends Resource

@export var run_speed: float = 220.0
@export var ground_accel: float = 1800.0
@export var ground_decel: float = 2200.0
@export var air_accel: float = 1200.0
@export var jump_velocity: float = -360.0
@export var gravity_scale: float = 1.0
@export var dash_speed: float = 340.0
@export var dash_duration: float = 0.18
@export var wall_slide_speed: float = 70.0
@export var wall_jump_velocity: Vector2 = Vector2(240.0, -320.0)
@export var invulnerability_time: float = 1.0
```

The player scene should reference one tuning resource instance, and the runtime controller should read values from it rather than store duplicate copies in code.

### Example player controller shape

The locomotion script should be state-aware, but it does not need to be a giant inheritance tree or an overly abstract framework.

```gdscript
extends CharacterBody2D

@export var tuning: PlayerTuning
@export var can_dash_from_start := false

var facing := 1
var locomotion_state: StringName = &"idle"
var dash_unlocked := false

func _physics_process(delta: float) -> void:
    var move_input := Input.get_axis("move_left", "move_right")
    var jump_pressed := Input.is_action_just_pressed("jump")
    var dash_pressed := Input.is_action_just_pressed("dash")

    _update_facing(move_input)
    _apply_horizontal_movement(move_input, delta)
    _apply_gravity(delta)
    _handle_jump(jump_pressed)
    _handle_dash(dash_pressed)

    move_and_slide()
    _update_locomotion_state()
```

Implementation direction:

- Player movement stays in `_physics_process`.
- Input is read through semantic actions only.
- Dash unlock rules are resolved through progression state, not hardcoded stage logic.
- Presentation should observe `locomotion_state` and `facing` instead of recomputing gameplay state from animations.

### Example hit and damage contract

Damage should move through a shared payload so player attacks, enemy attacks, contact damage, and boss weakness checks all speak the same language.

```gdscript
class_name HitData
extends RefCounted

var source: Node
var team: StringName
var weapon_id: StringName
var damage: int
var knockback: Vector2
```

```gdscript
class_name Hurtbox
extends Area2D

signal hit_received(hit: HitData)

@export var owner_team: StringName

func receive_hit(hit: HitData) -> void:
    if hit.team == owner_team:
        return

    hit_received.emit(hit)
```

This is intentionally simple. The actual implementation may add flags like `ignores_iframes`, `hit_pause_scale`, or `damage_kind`, but all damageable entities should still receive one consistent hit payload shape.

### Example weapon definition shape

Weapons should be represented by data plus reusable behavior hooks rather than giant `match` statements inside the player script.

```gdscript
class_name WeaponData
extends Resource

@export var weapon_id: StringName
@export var display_name: String
@export var energy_cost: int = 0
@export var projectile_scene: PackedScene
@export var base_damage: int = 1
@export var supports_charge := false
```

At runtime, `PlayerCombat` should read the equipped `WeaponData`, spawn the configured projectile scene if needed, and emit semantic events like `player_shoot` or `buster_charge_full` for presentation and audio.

### Example stage definition shape

Stage metadata should be authored as data and consumed by menus, progression logic, and scene flow.

```gdscript
class_name StageDefinition
extends Resource

@export var stage_id: StringName
@export var display_name: String
@export var stage_scene: PackedScene
@export var boss_id: StringName
@export var weapon_reward_id: StringName
@export var unlocked_by_default := false
@export var requires_intro_clear := true
```

### Example save payload shape

The initial save format should be a versioned JSON file stored at `user://save_01.json`.

```json
{
  "version": 1,
  "bosses_defeated": ["chill_penguin", "storm_eagle"],
  "weapons_unlocked": ["shotgun_ice", "storm_tornado"],
  "collected_pickups": [
    "intro_highway_dash_capsule",
    "storm_eagle_heart_tank"
  ],
  "armor_parts": {
    "helmet": false,
    "body": false,
    "arms": false,
    "legs": true
  },
  "sub_tanks": {
    "sub_tank_01": 8,
    "sub_tank_02": 0
  },
  "dash_unlocked": true,
  "intro_cleared": true,
  "fortress_unlocked": false
}
```

The runtime `Progression` autoload should own the live state. `SaveManager` converts that state to and from this payload.

## Feature Requirements

### 1. Input And Control Layer

The project needs a stable input abstraction before movement and combat are implemented.

#### Required input actions

- Move left and right.
- Jump.
- Dash.
- Shoot.
- Weapon cycle or weapon select.
- Pause.
- Menu confirm and cancel.

#### Device support

- Keyboard support is required from the start.
- Gamepad support is required from the start because the target play feel depends on controller-friendly input.
- Rebinding is not required for the first vertical slice, but the input action map must be organized so rebinding can be added later without changing gameplay code.

#### Design requirements

- Gameplay systems should read semantic input actions, not hardcoded keys or buttons.
- Menu input and gameplay input should be separable so pause and stage-select flows remain clean.

### 2. Core Player Controller

The player controller must reproduce the core feel of X-style movement at a mechanics level.

#### Required movement capabilities

- Ground movement with tuned acceleration and deceleration.
- Jumping with controllable jump height or equivalent variable-jump behavior.
- Air control that preserves intentional movement without becoming floaty.
- Dash with full state integration.
- Wall slide and wall jump.
- Facing direction updates and turn behavior that support responsive combat.
- Stable transitions between idle, run, jump, fall, dash, wall slide, hurt, and death states.

#### Survivability and interaction

- Damage intake with knockback.
- Temporary invulnerability after damage.
- Death handling and respawn behavior.
- Collision against terrain, moving platforms, and stage hazards.
- Ladder support is part of the full game architecture, but it is not required in Phase 1 unless the first stage slice needs it.

#### Campaign gating decision

- The movement system must support dash from Phase 1 for tuning and testing.
- In campaign progression, dash should be gated behind the intro-stage upgrade event by default, matching the original progression beat.
- Test scenes and debug stages may enable dash from the start to speed iteration.

#### Design requirements

- Movement tuning must be data-driven or otherwise isolated for fast iteration.
- Core movement logic must not depend on final animation assets.
- Movement state must be readable by combat, UI, audio, and presentation systems.

### 3. Player Combat

The player combat system must support the base buster loop first and remain extensible for Maverick weapons later.

#### Required combat capabilities

- Basic buster firing.
- Charge accumulation with at least neutral, partial-charge, and full-charge states.
- Charged shot release behavior.
- Projectile spawning, ownership, travel, lifetime, despawn, and collision.
- Distinction between player projectiles, enemy projectiles, and contact damage.

#### Extensibility requirements

- Weapon switching model for future boss weapons.
- Weapon energy model for non-buster weapons.
- Expandable weapon definitions using shared data and shared behavior contracts.
- Hooks for destructible world objects and breakable entities.

#### Combat behavior requirements

- The player must be able to fire while grounded and airborne.
- Charge state feedback must exist even with placeholder visuals and placeholder audio.
- The system must support boss weakness calculations without special-case boss code in the player weapon logic.

#### Weapon switching implementation

Weapon switching should be owned by a dedicated child node on the player, not by `GameFlow`, UI code, or giant `match` statements in `Player.gd`.

```gdscript
class_name WeaponInventory
extends Node

signal equipped_weapon_changed(weapon_id: StringName)

const ORDER: Array[StringName] = [
    &"buster",
    &"shotgun_ice",
    &"electric_spark",
    &"rolling_shield",
    &"homing_torpedo",
    &"boomerang_cutter",
    &"chameleon_sting",
    &"storm_tornado",
    &"fire_wave",
]

var unlocked := {
    &"buster": true,
}

var equipped_weapon_id: StringName = &"buster"

func unlock_weapon(weapon_id: StringName) -> void:
    unlocked[weapon_id] = true

func cycle_next() -> void:
    var current_index := ORDER.find(equipped_weapon_id)
    for offset in range(1, ORDER.size() + 1):
        var candidate := ORDER[(current_index + offset) % ORDER.size()]
        if unlocked.get(candidate, false):
            equipped_weapon_id = candidate
            equipped_weapon_changed.emit(equipped_weapon_id)
            return
```

```gdscript
class_name PlayerCombat
extends Node

@export var weapon_database: Dictionary

@onready var inventory: WeaponInventory = $WeaponInventory
@onready var shot_origin: Marker2D = $"../ShotOrigin"

func fire_pressed(owner_node: Node2D, facing: int) -> void:
    var weapon_data: WeaponData = weapon_database.get(inventory.equipped_weapon_id)
    if weapon_data == null:
        return

    if weapon_data.energy_cost > 0 and not owner_node.consume_weapon_energy(weapon_data.energy_cost):
        return

    var projectile := weapon_data.projectile_scene.instantiate()
    projectile.global_position = shot_origin.global_position
    projectile.setup(owner_node, facing, weapon_data)
    owner_node.get_tree().current_scene.add_child(projectile)

    AudioManager.play_sfx(&"player_shoot")
```

```gdscript
func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("weapon_next"):
        $PlayerCombat/WeaponInventory.cycle_next()
```

Rules:

- The Buster is always unlocked.
- Boss weapons are unlocked only through `Progression`.
- `Progression` restores unlocked weapons into `WeaponInventory` on stage load or player spawn.
- HUD listens to `equipped_weapon_changed` and updates without owning any combat logic.

#### Design requirements

- Weapon logic must remain separate from locomotion logic.
- Damage delivery must go through a shared hit and damage contract.
- Combat events must emit semantic feedback hooks for UI, audio, VFX, and camera effects.

### 4. Health, Damage, And Collision Rules

Combat needs a stable shared contract before enemy and boss content scales up.

#### Required shared rules

- A consistent damage payload or hit description that includes at least source, damage amount, damage type or weapon identity, knockback intent, and team ownership.
- Distinct collision layers or collision groups for terrain, player body, enemy body, player projectiles, enemy projectiles, hurtboxes, hitboxes, pickups, and triggers.
- Clear ownership rules so entities cannot damage allies unless explicitly intended.

#### Required outcomes

- Hurt reactions.
- Invulnerability windows where applicable.
- Death callbacks.
- Drop spawning hooks.
- Feedback events for UI, audio, and presentation.

#### Collision layer plan

Use explicit named layers from the start. The exact layer numbers below should remain stable.

| Layer | Name |
| --- | --- |
| 1 | `WORLD_SOLID` |
| 2 | `WORLD_ONE_WAY` |
| 3 | `PLAYER_BODY` |
| 4 | `ENEMY_BODY` |
| 5 | `PLAYER_HITBOX` |
| 6 | `ENEMY_HITBOX` |
| 7 | `PLAYER_HURTBOX` |
| 8 | `ENEMY_HURTBOX` |
| 9 | `PICKUP` |
| 10 | `TRIGGER` |
| 11 | `HAZARD` |
| 12 | `CAMERA_ZONE` |
| 13 | `PLAYER_SENSOR` |

Recommended usage:

- `CharacterBody2D` nodes should mainly collide with `WORLD_SOLID` and `WORLD_ONE_WAY`.
- Damage detection should use `Area2D` hitboxes and hurtboxes, not body collisions.
- Pickups, checkpoints, cutscene triggers, and camera zones should be implemented as `Area2D` triggers.
- Hazards like spikes should generally use `Area2D` and deliver damage or instant death through the same hit or hazard pipeline.

#### Collision constants example

```gdscript
class_name CollisionLayers
extends RefCounted

const WORLD_SOLID := 1
const WORLD_ONE_WAY := 2
const PLAYER_BODY := 3
const ENEMY_BODY := 4
const PLAYER_HITBOX := 5
const ENEMY_HITBOX := 6
const PLAYER_HURTBOX := 7
const ENEMY_HURTBOX := 8
const PICKUP := 9
const TRIGGER := 10
const HAZARD := 11
const CAMERA_ZONE := 12
const PLAYER_SENSOR := 13

static func bit(layer_index: int) -> int:
    return 1 << (layer_index - 1)
```

#### Collision setup examples

```gdscript
# Player body
collision_layer = CollisionLayers.bit(CollisionLayers.PLAYER_BODY)
collision_mask = (
    CollisionLayers.bit(CollisionLayers.WORLD_SOLID)
    | CollisionLayers.bit(CollisionLayers.WORLD_ONE_WAY)
)
```

```gdscript
# Player hurtbox
collision_layer = CollisionLayers.bit(CollisionLayers.PLAYER_HURTBOX)
collision_mask = (
    CollisionLayers.bit(CollisionLayers.ENEMY_HITBOX)
    | CollisionLayers.bit(CollisionLayers.HAZARD)
)
```

```gdscript
# Player sensor for pickups and triggers
collision_layer = CollisionLayers.bit(CollisionLayers.PLAYER_SENSOR)
collision_mask = (
    CollisionLayers.bit(CollisionLayers.PICKUP)
    | CollisionLayers.bit(CollisionLayers.TRIGGER)
    | CollisionLayers.bit(CollisionLayers.CAMERA_ZONE)
)
```

### 5. Enemy Framework

The project needs a reusable enemy framework rather than one-off enemy implementations.

#### Shared enemy contract

- Health and death handling.
- Hurt reactions.
- Contact damage.
- Projectile or attack behavior support.
- Optional drop behavior.
- Spawn, off-screen suspension, and despawn rules tied to stage flow.

#### Behavior model

- Enemies should use a clear behavior model such as state machines or modular action patterns.
- The framework must support simple enemies, patrol enemies, turrets, flying enemies, and encounter-specific enemies.
- Enemy-specific behavior should reuse the shared health, damage, and drop systems.

#### Presentation requirements

- Placeholder visuals must communicate facing, attack state, hurt state, and death state clearly.
- Hit flash, death feedback, and spawn effects must exist as semantic hooks even if the first pass uses simple color flashes or temporary shapes.

#### Inheritance and composition plan

Use shallow inheritance and composition-heavy actor scenes.

- `ActorBase.gd` for shared actor capabilities like facing, basic health hooks, team identity, and common helpers.
- `EnemyBase.gd` extends `ActorBase.gd`.
- `BossBase.gd` extends `ActorBase.gd`.

Enemy and boss scenes should compose behavior from child nodes and helper scripts:

- `Hurtbox`
- `HitboxEmitter`
- `EnemyBrain`
- `DropSpawner`
- `PresentationController`
- `BossPhaseController` for bosses only

Recommended enemy scene shape:

```text
Enemy_WalkerBasic.tscn
- EnemyWalkerBasic (CharacterBody2D)
  - CollisionShape2D
  - VisualRoot
  - Hurtbox
  - VisionArea
  - AttackOrigin
  - EnemyBrain
  - DropSpawner
```

#### AI logic approach

Enemy AI should be implemented with small state-machine nodes or state scripts, not one huge `_physics_process` full of conditionals.

```gdscript
class_name EnemyState
extends Node

func enter(_context: Dictionary = {}) -> void:
    pass

func physics_update(_delta: float) -> void:
    pass

func exit() -> void:
    pass
```

```gdscript
class_name EnemyBrain
extends Node

@export var initial_state: NodePath

var current_state: EnemyState

func transition_to(state: EnemyState, context: Dictionary = {}) -> void:
    if current_state:
        current_state.exit()
    current_state = state
    current_state.enter(context)

func physics_update(delta: float) -> void:
    if current_state:
        current_state.physics_update(delta)
```

Typical reusable enemy states:

- `IdleState`
- `PatrolState`
- `ChaseState`
- `AttackState`
- `RecoverState`
- `DeadState`

### 6. Boss Framework

Bosses need a dedicated encounter framework layered on top of the shared enemy and combat systems.

#### Boss encounter requirements

- Boss intro sequence hook.
- Boss arena activation and lock-in flow.
- Boss health bar support.
- Multi-phase or state-driven attack behavior.
- Boss defeat sequence and reward flow.

#### Combat requirements

- Weakness and resistance support for special weapons.
- Shared damage handling compatible with the global combat contract.
- Explicit boss state transitions for intro, active combat, recovery or stagger if used, defeat, and post-fight reward resolution.

#### Reward requirements

- Boss defeat must update progression data.
- Boss reward flow must support weapon unlocks and stage-clear resolution.

#### Boss scene composition

Bosses should share the same shallow-architecture philosophy as enemies, but with extra phase and arena control.

```text
Boss_ChillPenguin.tscn
- BossChillPenguin (CharacterBody2D)
  - CollisionShape2D
  - VisualRoot
  - Hurtbox
  - AttackOrigin
  - BossPhaseController
  - ArenaAnchor
  - IntroMarker
```

#### Boss AI approach

- Bosses should use a phase controller that selects attack states based on health thresholds, cooldown windows, and context.
- Attack behaviors should be individual reusable scripts or nodes when practical.
- Weakness reactions should be driven by data and hooks in the damage pipeline, not duplicated boss-specific weapon checks.

Example:

```gdscript
class_name BossPhaseController
extends Node

@export var phase_thresholds: Array[int] = [100, 60, 30]
var current_phase := 0

func update_phase(current_health_percent: int) -> void:
    if current_phase + 1 < phase_thresholds.size() and current_health_percent <= phase_thresholds[current_phase + 1]:
        current_phase += 1
```

### 7. Stage, Camera, And World Systems

The world layer must support traversal, encounter orchestration, and readable camera behavior.

#### Stage requirements

- Stage scenes with clear entry and exit flow.
- Spawn points and checkpoints.
- Hazards such as pits, spikes, damage volumes, and moving threats.
- Moving platforms and reusable environment interaction patterns.
- Event triggers for encounters, boss intros, gates, tutorials, scripted transitions, and stage completion.

#### Camera requirements

- A side-scrolling gameplay camera with stable follow behavior.
- Camera constraints and zone overrides for traversal and boss encounters.
- Room-lock behavior for boss arenas and other set-piece encounters.
- Support for camera shake hooks driven by gameplay events.

#### Authoring requirements

- Stages should be built from reusable gameplay building blocks where practical.
- Stage-specific scripting should remain simple and explicit.
- Intro stage support is required because it drives dash upgrade progression.

#### Stage controller responsibilities

Each stage scene should have a `StageController.gd` root script that owns:

- Spawn and respawn routing.
- Checkpoint activation.
- Stage-local boss references.
- Trigger wiring.
- Camera-zone activation.
- Stage-complete signaling.
- Stage-local cutscene entry points.

Example:

```gdscript
extends Node

@export var stage_data: StageDefinition
@export var player_spawn_root: NodePath

func start_stage() -> void:
    _spawn_player_at_default_spawn()
    AudioManager.play_music(stage_data.stage_id)
```

### 8. Progression And Game Flow

The game-wide progression layer must support both single-stage play and campaign continuity.

#### Front-end flow

- Title screen.
- Main menu.
- Intro stage entry.
- Stage select flow after intro stage completion.
- Pause flow.
- Stage completion flow.
- Endgame or fortress flow after the Maverick progression loop is satisfied.

#### Progression systems

- Intro-stage dash unlock gating.
- Boss defeat tracking.
- Weapon unlock tracking.
- Armor upgrade tracking.
- Heart tank tracking.
- Sub tank ownership and fill state tracking.
- Save and load of long-term progression.

#### Save model decision

- Use one local save profile for the initial implementation.
- Save data must include defeated bosses, unlocked weapons, collected upgrades, health expansion state, sub tank ownership and fill state, and relevant campaign progression flags.
- Checkpoints are stage-session state and should not be treated as permanent long-term save data unless a later feature explicitly expands save behavior.

#### Retry model decision

- Early development and the first vertical slice will use immediate retry from checkpoint or stage start instead of replicating the original life economy in full detail.
- Lives and continues are not required for the first implementation milestones.
- If a classic lives system is added later, it must be layered on top of the existing stage retry flow rather than entangled with core movement or combat logic.

#### Level selection implementation

The stage-select screen should be a dedicated scene such as `scenes/ui/stage_select_menu.tscn`.

- It should render a fixed roster of stage cards based on `StageDefinition` resources.
- Stage order should be explicit, not inferred from filesystem order.
- `Progression` determines whether a stage is unlocked, cleared, or still locked.
- After intro stage clear, the eight Maverick stages become selectable.
- After the required Maverick progression flags are complete, fortress stages become available.

```gdscript
extends Control

@export var stage_definitions: Array[StageDefinition]

func _ready() -> void:
    for stage_def in stage_definitions:
        _add_stage_card(stage_def, Progression.is_stage_unlocked(stage_def.stage_id))

func _on_stage_selected(stage_id: StringName) -> void:
    GameFlow.request_stage_load(stage_id)
```

#### Save serialization implementation

The first implementation should use JSON for readability and easy debugging. The save file should be versioned and stored in `user://save_01.json`.

```gdscript
extends Node

const SAVE_PATH := "user://save_01.json"

func save_game() -> void:
    var payload := Progression.to_save_payload()
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    file.store_string(JSON.stringify(payload, "\t"))

func load_game() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        return

    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    var payload := JSON.parse_string(file.get_as_text())
    Progression.load_from_save_payload(payload)
```

The serialized payload should include:

- Save format version.
- Boss defeat flags.
- Weapon unlock flags.
- Persistent pickup collection IDs.
- Armor unlock flags.
- Dash unlock flag.
- Sub tank ownership and fill values.
- Intro-clear flag.
- Fortress-unlock flag.
- Any ending-unlock flags required later.

The serialized payload should not include:

- Live enemy instances.
- Temporary health pickups.
- Current checkpoint as a permanent campaign fact.
- Moment-to-moment player HP or weapon energy unless a future suspend-save system is added.

#### Script interaction with save and progression

- Stages read `Progression` at load time to decide which persistent pickups to spawn and which gates or routes should be open.
- `SaveManager` reads from and writes to `Progression`.
- `GameFlow` decides when saves should be triggered, such as after stage clear or after an explicit menu save action.

### 8A. Cutscenes

Cutscenes should be data-driven and controlled by stage or flow logic, not hardcoded inside player scripts.

#### Cutscene use cases

- Intro stage opening.
- Zero rescue sequence.
- Dr. Light capsule sequences.
- Boss intro stingers.
- Stage-clear weapon reward flow.
- Ending and fortress transitions.

#### Cutscene architecture

- `GameFlow` enters `CUTSCENE` state and suppresses gameplay input.
- `CutsceneDirector.gd` owns timeline playback.
- `CutsceneStep` resources describe discrete actions.
- Actors expose simple cutscene-safe methods such as `set_input_enabled`, `play_presentation_state`, `move_to_marker`, or `look_at_direction`.

```gdscript
class_name CutsceneStep
extends Resource

@export var action: StringName
@export var target_path: NodePath
@export var duration: float = 0.0
@export var text_id: StringName
@export var marker_name: StringName
```

```gdscript
class_name CutsceneDirector
extends Node

@export var steps: Array[CutsceneStep]

func play() -> void:
    GameFlow.enter_cutscene_mode()
    for step in steps:
        await _run_step(step)
    GameFlow.exit_cutscene_mode()
```

Supported cutscene actions in the first implementation:

- `move_actor`
- `play_animation_state`
- `camera_pan_to_marker`
- `wait`
- `show_text`
- `emit_audio_event`
- `unlock_dash`
- `end_stage`

Cutscenes should interact with gameplay state through `GameFlow`, `Progression`, and stage-local script APIs. They should not mutate unrelated systems directly.

### 9. UI And Feedback

UI should present gameplay state clearly while remaining decoupled from gameplay logic.

#### Required UI areas

- Title and main menu UI.
- Player HUD for health.
- Weapon energy display when non-buster weapons are active.
- Boss health display.
- Pause menu.
- Stage select UI.
- Save or profile UI if needed for the single-profile flow.

#### Feedback systems

- Hit flashes.
- Charge indicators.
- Damage feedback.
- Screen shake hooks.
- Placeholder animation and VFX support for movement and combat states.
- Stage clear and weapon unlock feedback hooks.

#### Design requirements

- UI widgets should observe gameplay state rather than own gameplay decisions.
- Feedback triggers should use semantic events so they remain stable when assets change later.

### 10. Audio System

An audio system is required even before real assets exist.

#### Audio architecture requirements

- Separate routing for music and sound effects.
- Semantic event-driven playback API for gameplay and UI events.
- Support for placeholder clips and placeholder music loops.
- Category-based volume control.
- Support for scene-local effects and cross-scene music control.

#### Required semantic events

- `player_jump`
- `player_dash`
- `player_shoot`
- `buster_charge_start`
- `buster_charge_full`
- `player_hurt`
- `enemy_defeat`
- `boss_intro`
- `boss_defeat`
- `checkpoint_activated`
- `stage_clear`
- `menu_confirm`
- `menu_cancel`

#### Design requirements

- Gameplay code must trigger audio by meaning, not by file path.
- Replacing placeholder clips with final assets must not require gameplay rewrites.
- Missing placeholder clips must fail gracefully without breaking gameplay.

#### Recommended implementation approach

- Implement audio as an autoload such as `AudioManager`.
- Use Godot audio buses for at least `Master`, `Music`, and `SFX`.
- Map semantic event IDs to placeholder `AudioStream` assets through data, not hardcoded branches spread across gameplay code.
- Allow both one-shot SFX playback and persistent music playback through separate methods.

#### Example audio manager shape

```gdscript
extends Node

var sfx_events: Dictionary = {}
var music_events: Dictionary = {}

func play_sfx(event_name: StringName) -> void:
    var stream: AudioStream = sfx_events.get(event_name)
    if stream == null:
        return

    var player := AudioStreamPlayer.new()
    player.bus = "SFX"
    player.stream = stream
    add_child(player)
    player.finished.connect(player.queue_free)
    player.play()

func play_music(track_name: StringName) -> void:
    var stream: AudioStream = music_events.get(track_name)
    if stream == null:
        return

    $MusicPlayer.stream = stream
    $MusicPlayer.play()
```

Example gameplay usage:

```gdscript
if Input.is_action_just_pressed("jump") and is_on_floor():
    velocity.y = tuning.jump_velocity
    AudioManager.play_sfx(&"player_jump")
```

This is the intended dependency direction: gameplay emits a semantic request, and the audio system decides what stream to play, on what bus, and how to handle missing placeholders.

### 11. Placeholder Asset Pipeline

Placeholder-first development is part of the spec, not a temporary workaround.

#### Placeholder requirements

- Use clearly named placeholder sprites, shapes, animations, VFX markers, and audio placeholders.
- Keep placeholder asset naming stable across systems.
- Build animation and state hookups around semantic states, not asset-specific assumptions.
- Keep collision shapes, hurtboxes, and hitboxes authored independently from final art.
- Use simple, readable color and shape language so placeholder entities are visually distinguishable during gameplay testing.

#### Swap-readiness requirements

- A future art or audio pass must be able to replace placeholders without changing gameplay behavior.
- Character, enemy, projectile, UI, and stage placeholders must all follow consistent naming and scene conventions.
- Presentation-facing scenes should be swappable while preserving the same gameplay node contracts.

## Public Gameplay Contracts

The implementation should preserve the following high-level contracts so systems remain reusable and replaceable.

### Player state contract

The player system should expose:

- Current locomotion state.
- Facing direction.
- Health state and invulnerability state.
- Charge state.
- Equipped weapon.
- Upgrade capability flags such as dash and armor unlocks.

### Weapon contract

Each weapon definition should provide or describe:

- Weapon identity.
- Fire behavior.
- Charge behavior if applicable.
- Energy cost.
- Damage profile.
- Projectile or hit behavior.
- Compatibility with weakness and resistance checks.

### Damageable contract

Enemies, bosses, destructibles, and optionally the player should share a damage intake contract that supports:

- Receiving hit data.
- Evaluating weakness or resistance modifiers.
- Triggering hurt and death callbacks.
- Emitting feedback hooks for UI, audio, VFX, and camera systems.

### Audio contract

Gameplay systems should emit semantic events rather than direct file references. The audio layer owns clip lookup, category routing, and fallback behavior.

### Save and progression contract

The progression layer should be able to track:

- Defeated bosses.
- Unlocked weapons.
- Collected upgrades.
- Health capacity upgrades.
- Sub tank ownership and fill state.
- Dash unlock state.
- Relevant campaign progression flags.

### Stage contract

Each stage should define:

- Player spawn point.
- Checkpoint data.
- Boss arena trigger data if applicable.
- Stage-clear trigger.
- Stage-specific event hooks.
- Stage metadata needed for progression and scene flow.

## Milestones

### Phase 1: Foundation

Build the reusable technical foundation required for repeatable feature work.

- Establish project structure for scenes, scripts, data, UI, audio, and placeholders.
- Define the input action map and baseline device support.
- Implement the player controller with run, jump, fall, wall interaction, dash support, damage, death, and respawn.
- Implement the base combat system with basic buster fire and charge states.
- Create the shared health, damage, hit, and collision conventions.
- Create reusable enemy and boss skeletons.
- Create the gameplay camera foundation and boss-room constraint support.
- Create the audio manager and semantic event routing with placeholder support.
- Create the initial HUD shell.
- Define placeholder asset conventions and swap rules.

### Phase 2: Vertical Slice

Build one playable end-to-end slice that proves the architecture.

- Create one complete stage slice with traversal, hazards, checkpoints, and stage completion flow.
- Add at least one reusable enemy family.
- Add one boss encounter using the boss framework.
- Connect player, combat, enemies, boss, HUD, progression hooks, camera, and audio end-to-end.
- Validate death, respawn, boss defeat, dash unlock gating, and stage clear flow using placeholders only.

### Phase 3: Full Game Systems

Expand from the vertical slice into the campaign-wide structure.

- Build title flow, intro stage flow, and stage select flow.
- Add special weapon switching and energy usage.
- Add boss weakness tables.
- Add armor upgrades, heart tanks, and sub tanks.
- Add save/load progression.
- Expand reusable stage authoring patterns for multiple stages.
- Build enough endgame flow to support fortress progression and final boss sequencing.

### Phase 4: Completion And Polish

Finish the full remake content and improve overall feel.

- Add the remaining stages and bosses.
- Tune movement, combat, camera, and boss pacing across the whole game.
- Improve placeholder feedback or replace it with production assets.
- Improve readability, usability, and accessibility where practical.
- Perform optimization, bug fixing, and content consistency passes.

## Out Of Scope For Initial Implementation

- Pixel-perfect audiovisual recreation.
- Exact emulation of every SNES-era timing detail.
- Final art production, final audio production, and full polish before core systems are proven.
- Multiplayer and online features.
- Modding support.
- Mobile support.
- General-purpose editor tooling beyond what directly supports this game.

## Validation And Acceptance Scenarios

The implementation should be considered on track when the following scenarios are possible.

### Mechanics baseline

- The player can run, jump, wall jump, dash, shoot, charge, take damage, die, and respawn reliably.
- Core movement and combat values can be tuned without rewriting major systems.
- The player controller works with keyboard and gamepad through the same action map.

### Placeholder-first workflow

- Placeholder art and audio can be swapped without rewriting gameplay logic.
- Core collisions and behaviors remain stable when presentation assets change.
- Presentation scenes can be updated without changing movement, combat, or progression code.

### Vertical slice validation

- One stage slice can be played from start to boss clear using only placeholder assets.
- The slice includes traversal, hazards, checkpoints, at least one enemy family, one boss, death and respawn, and stage completion.
- The intro-stage upgrade flow can unlock dash for campaign progression while debug scenes can still test dash immediately.

### Progression validation

- Boss defeat updates progression state and unlock hooks.
- Save/load restores progression-related unlocks and collected upgrades correctly.
- Retry from checkpoint or stage start functions without relying on a lives system.

### Audio, camera, and UI validation

- Audio responds to gameplay and menu events through semantic triggers.
- The camera handles normal traversal, encounter locking, and boss arenas cleanly.
- The HUD reflects player health, weapon state, charge state, and boss health correctly.

### Extensibility validation

- Adding a new enemy, boss, weapon, or stage follows existing framework patterns rather than bespoke one-off implementations.
- Adding a new placeholder presentation asset does not require changes to gameplay contracts.

## Assumptions

- The project is a 2D side-scrolling action platformer in Godot 4.6.
- Mechanics fidelity is prioritized over pixel-perfect recreation.
- Placeholder-first development is a hard architectural requirement until production assets exist.
- The first implementation target is a vertical slice, not full-game content breadth.
- Dash is technically available in the player controller from Phase 1 but is campaign-gated by intro progression.
- The first save implementation uses a single local profile.
- The first retry model uses checkpoint or stage restart, not a full lives economy.

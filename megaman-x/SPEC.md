# SPEC.md

## Summary

Recreate *Mega Man X* (1993) in Godot 4.6 as a mechanics-first 2D action platformer. Use placeholder visuals and placeholder audio, but build the runtime structure so real assets can replace them later without changing gameplay logic.

The target campaign includes:

- `intro_highway`
- the 8 Maverick stages
- Sigma Fortress stages
- final Sigma fights
- boss weapons
- armor parts
- heart tanks
- sub tanks

## Runtime Services

Use these autoloads only:

- `autoloads/game_flow.gd`
- `autoloads/progression.gd`
- `autoloads/save_manager.gd`
- `autoloads/audio_manager.gd`

### `GameFlow`

Owns high-level runtime state and scene transitions.

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

Responsibilities:

- boot flow
- title/menu flow
- stage loading
- pause/unpause
- cutscene mode
- stage clear flow
- ending flow

### `Progression`

Owns in-memory campaign state.

```gdscript
extends Node

signal progression_changed()

var bosses_defeated: Dictionary = {}
var weapons_unlocked: Dictionary = { &"buster": true }
var collected_pickups: Dictionary = {}
var armor_parts := {
    &"helmet": false,
    &"body": false,
    &"arms": false,
    &"legs": false,
}
var dash_unlocked := false
var intro_cleared := false
var fortress_unlocked := false
```

Responsibilities:

- unlocked weapons
- persistent pickups
- armor parts
- dash unlock
- boss defeat flags
- stage availability flags

### `SaveManager`

Owns serialization only. It does not own gameplay rules.

- save to `user://save_01.json`
- load from `user://save_01.json`
- version the payload
- convert `Progression` to/from save data

### `AudioManager`

Owns music playback, SFX playback, buses, and semantic event lookup.

## Player

Keep all player-related implementation here: input, movement, combat, health hookup, pickups, and state machines.

### Player scene

```text
Player.tscn
- Player (CharacterBody2D) [Player.gd]
  - CollisionShape2D
  - VisualRoot
  - Hurtbox [Hurtbox.gd]
  - HealthComponent [HealthComponent.gd]
  - PlayerCombat [PlayerCombat.gd]
    - WeaponInventory [WeaponInventory.gd]
  - PickupReceiver [PickupReceiver.gd]
  - PlayerSensor (Area2D)
  - ShotOrigin (Marker2D)
  - WallCheckLeft (RayCast2D)
  - WallCheckRight (RayCast2D)
  - CameraAnchor (Marker2D)
```

### Input

Required actions:

- `move_left`
- `move_right`
- `jump`
- `dash`
- `shoot`
- `weapon_next`
- `pause`
- `menu_confirm`
- `menu_cancel`

Both keyboard and gamepad are required. Gameplay code reads actions only, not raw keys/buttons.

### Player tuning data

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

### Player controller

`Player.gd` owns locomotion, facing, and movement-facing state only.

```gdscript
extends CharacterBody2D

@export var tuning: PlayerTuning
@export var can_dash_from_start := false

var facing := 1
var dash_unlocked := false
var is_dashing := false
var is_hurt := false
var is_dead := false

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

### Player locomotion state machine

Use a single locomotion state machine in `Player.gd`.

```gdscript
enum LocomotionState {
    IDLE,
    RUN,
    JUMP,
    FALL,
    DASH,
    WALL_SLIDE,
    HURT,
    DEAD,
}
```

```gdscript
var locomotion_state: LocomotionState = LocomotionState.IDLE
```

Priority order:

- `DEAD`
- `HURT`
- `DASH`
- `WALL_SLIDE`
- `JUMP`
- `FALL`
- `RUN`
- `IDLE`

```gdscript
func _update_locomotion_state() -> void:
    if is_dead:
        locomotion_state = LocomotionState.DEAD
        return

    if is_hurt:
        locomotion_state = LocomotionState.HURT
        return

    if is_dashing:
        locomotion_state = LocomotionState.DASH
        return

    if _is_wall_sliding():
        locomotion_state = LocomotionState.WALL_SLIDE
        return

    if not is_on_floor():
        locomotion_state = (
            LocomotionState.JUMP
            if velocity.y < 0.0
            else LocomotionState.FALL
        )
        return

    locomotion_state = (
        LocomotionState.RUN
        if absf(velocity.x) > 0.0
        else LocomotionState.IDLE
    )
```

Rules:

- dash exists in code from Phase 1
- campaign dash unlock is gated by the intro-stage capsule
- debug scenes can enable dash immediately
- ladder support is part of the full game but not required in the first slice unless needed by the chosen test stage

### Player combat

`PlayerCombat.gd` owns weapon firing, charging, cooldown, and projectile spawning. It does not own locomotion.

```gdscript
class_name WeaponData
extends Resource

@export var weapon_id: StringName
@export var display_name: String
@export var energy_cost: int = 0
@export var projectile_scene: PackedScene
@export var base_damage: int = 1
@export var supports_charge := false
@export var full_charge_time := 1.0
@export var max_charge_level := 2
```

#### Weapon switching

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

#### Combat state machine

Use a separate combat state machine in `PlayerCombat.gd`.

```gdscript
enum CombatState {
    READY,
    FIRING,
    CHARGING,
    CHARGED,
    COOLDOWN,
    DISABLED,
}
```

```gdscript
var combat_state: CombatState = CombatState.READY
var charge_time := 0.0
```

```gdscript
func physics_update(delta: float) -> void:
    if combat_state == CombatState.DISABLED:
        return

    if Input.is_action_pressed("shoot"):
        _handle_fire_held(delta)
    elif Input.is_action_just_released("shoot"):
        _handle_fire_released()
    elif Input.is_action_just_pressed("shoot"):
        _handle_fire_pressed()

    _update_cooldown(delta)
```

```gdscript
func _handle_fire_held(delta: float) -> void:
    var weapon_data: WeaponData = _get_equipped_weapon_data()
    if not weapon_data.supports_charge:
        return

    if combat_state == CombatState.READY:
        combat_state = CombatState.CHARGING
        charge_time = 0.0
        AudioManager.play_sfx(&"buster_charge_start")

    if combat_state == CombatState.CHARGING:
        charge_time += delta
        if charge_time >= weapon_data.full_charge_time:
            combat_state = CombatState.CHARGED
            AudioManager.play_sfx(&"buster_charge_full")
```

```gdscript
func _handle_fire_released() -> void:
    var weapon_data: WeaponData = _get_equipped_weapon_data()

    match combat_state:
        CombatState.CHARGING:
            _spawn_projectile(weapon_data, _resolve_partial_charge_level())
        CombatState.CHARGED:
            _spawn_projectile(weapon_data, weapon_data.max_charge_level)
        _:
            return

    combat_state = CombatState.COOLDOWN
    charge_time = 0.0
```

Locomotion and combat run in parallel. These combinations must work:

- `RUN + READY`
- `JUMP + FIRING`
- `DASH + CHARGING`
- `WALL_SLIDE + CHARGED`
- `HURT + DISABLED`

### Player pickups

Pickups should apply effects through `PickupReceiver.gd`, not through `Player.gd`.

```gdscript
class_name PickupReceiver
extends Node

@onready var health: HealthComponent = $"../HealthComponent"
@onready var combat: PlayerCombat = $"../PlayerCombat"

func apply_pickup(pickup_data: PickupData) -> void:
    match pickup_data.pickup_type:
        &"health":
            health.heal(pickup_data.health_amount)
        &"weapon_energy":
            combat.restore_weapon_energy(pickup_data.weapon_energy_amount)
        &"heart_tank":
            Progression.unlock_heart_tank(pickup_data.pickup_id)
        &"sub_tank":
            Progression.unlock_sub_tank(pickup_data.pickup_id)
        &"armor_capsule":
            Progression.unlock_armor_part(pickup_data.armor_part)
```

`PlayerSensor` should detect pickup `Area2D`s and pass them to `PickupReceiver`.

## Shared Gameplay Systems

This section contains systems shared by player, enemies, bosses, and the world.

### Health and damage

Use one shared hit payload shape and one shared health component.

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

```gdscript
class_name HealthComponent
extends Node

signal damaged(hit: HitData, current_health: int)
signal died()

@export var max_health := 1
@export var invulnerability_time := 0.0

var current_health := 0
var invulnerable := false

func _ready() -> void:
    current_health = max_health

func apply_hit(hit: HitData) -> void:
    if invulnerable:
        return

    current_health = max(current_health - hit.damage, 0)
    damaged.emit(hit, current_health)

    if current_health == 0:
        died.emit()
```

### Collision layers

Keep these layer numbers stable:

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

Recommended usage:

- bodies collide with world layers
- hitboxes and hurtboxes are `Area2D`
- pickups/checkpoints/cutscene triggers/camera zones are `Area2D`
- hazards use `Area2D` and the same hit/hazard pipeline

## Enemies And Bosses

### Campaign roster

Stages and bosses:

- `intro_highway` with scripted `vile_ride_armor`
- `chill_penguin`
- `spark_mandrill`
- `armored_armadillo`
- `launch_octopus`
- `boomer_kuwanger`
- `sting_chameleon`
- `storm_eagle`
- `flame_mammoth`
- `sigma_fortress_1` with `bospider`
- `sigma_fortress_2` with `rangda_bangda`
- `sigma_fortress_3` with `velguarder`
- `sigma_fortress_4` with `sigma_first_form` and `sigma_wolf_form`

Weapon rewards:

- `shotgun_ice`
- `electric_spark`
- `rolling_shield`
- `homing_torpedo`
- `boomerang_cutter`
- `chameleon_sting`
- `storm_tornado`
- `fire_wave`

Regular enemy families should use stable internal IDs such as:

- `walker_basic`
- `turret_basic`
- `hopper_basic`
- `flying_drone_basic`
- `shield_guard_basic`
- `mine_dropper_basic`

### Enemy scene and logic

Enemy inheritance stays shallow:

- `EnemyBase.gd` extends `CharacterBody2D`
- `HealthComponent.gd` handles HP
- `Hurtbox.gd` handles incoming hit routing
- `EnemyBrain.gd` handles AI state transitions

```text
Enemy_WalkerBasic.tscn
- EnemyWalkerBasic (CharacterBody2D) [EnemyBase.gd]
  - CollisionShape2D
  - VisualRoot
  - Hurtbox
  - HealthComponent
  - VisionArea
  - AttackOrigin
  - EnemyBrain
  - DropSpawner
```

```gdscript
class_name EnemyBase
extends CharacterBody2D

signal died(enemy_id: StringName)

@export var enemy_id: StringName
@export var team: StringName = &"enemy"

@onready var hurtbox: Hurtbox = $Hurtbox
@onready var health: HealthComponent = $HealthComponent
@onready var brain: EnemyBrain = $EnemyBrain

func _ready() -> void:
    hurtbox.hit_received.connect(health.apply_hit)
    health.died.connect(_on_died)

func _physics_process(delta: float) -> void:
    brain.physics_update(delta)

func _on_died() -> void:
    died.emit(enemy_id)
    queue_free()
```

### Enemy AI

Use small state scripts, not one giant `_physics_process()`.

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

Reusable state types:

- `IdleState`
- `PatrolState`
- `ChaseState`
- `AttackState`
- `RecoverState`
- `DeadState`

### Boss scene and logic

Bosses use the same shared systems plus a phase controller.

```text
Boss_ChillPenguin.tscn
- BossChillPenguin (CharacterBody2D) [BossBase.gd]
  - CollisionShape2D
  - VisualRoot
  - Hurtbox
  - HealthComponent
  - BossPhaseController
  - AttackOrigin
  - IntroMarker
  - ArenaMarker
```

```gdscript
class_name BossBase
extends CharacterBody2D

signal boss_defeated(boss_id: StringName)

@export var boss_id: StringName
@export var team: StringName = &"enemy"

@onready var hurtbox: Hurtbox = $Hurtbox
@onready var health: HealthComponent = $HealthComponent
@onready var phase_controller: BossPhaseController = $BossPhaseController

func _ready() -> void:
    hurtbox.hit_received.connect(_on_hit_received)
    health.died.connect(_on_died)

func _on_hit_received(hit: HitData) -> void:
    health.apply_hit(hit)
    phase_controller.update_phase(_health_percent())

func _on_died() -> void:
    boss_defeated.emit(boss_id)
```

```gdscript
class_name BossPhaseController
extends Node

@export var phase_thresholds: Array[int] = [100, 60, 30]
var current_phase := 0

func update_phase(current_health_percent: int) -> void:
    if current_phase + 1 < phase_thresholds.size() and current_health_percent <= phase_thresholds[current_phase + 1]:
        current_phase += 1
```

Boss requirements:

- intro hook
- health bar
- arena lock
- weakness/resistance handling
- reward flow through `Progression`

## Stages, Camera, And Pickups

### Stage data

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

### Stage scene layout

```text
Stage_FlameMammoth.tscn
- StageController (Node)
  - CameraController (Camera2D)
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
```

### Stage controller

`StageController.gd` owns stage-local flow:

- player spawn
- checkpoint activation
- trigger wiring
- stage-local boss references
- camera zone activation
- stage complete signaling
- stage-local cutscene entry points

```gdscript
extends Node

@export var stage_data: StageDefinition
@export var player_spawn_root: NodePath
@export var debug_spawn_id: StringName = &""
@export var debug_use_test_progression := true

func _ready() -> void:
    if GameFlow.current_state == GameFlow.GameState.BOOT:
        _start_standalone_test_mode()
    else:
        start_stage()

func start_stage() -> void:
    _spawn_player_at_default_spawn()
    AudioManager.play_music(stage_data.stage_id)

func _start_standalone_test_mode() -> void:
    if debug_use_test_progression:
        Progression.apply_debug_profile(&"all_movement_unlocked")
    _spawn_player_at_spawn(debug_spawn_id if debug_spawn_id != &"" else &"start")
    AudioManager.play_music(stage_data.stage_id)
```

This allows direct stage testing from the editor without going through the full boot flow.

### Camera

Use one gameplay camera per stage, not multiple active gameplay cameras.

Use camera modes:

- `FOLLOW`
- `ZONE_LOCK`
- `BOSS_LOCK`
- `CUTSCENE`

```gdscript
class_name CameraController
extends Camera2D

enum CameraMode {
    FOLLOW,
    ZONE_LOCK,
    BOSS_LOCK,
    CUTSCENE,
}

@export var follow_target: Node2D
@export var horizontal_smooth := 8.0
@export var vertical_smooth := 4.0

var camera_mode := CameraMode.FOLLOW
var camera_bounds := Rect2()

func _process(delta: float) -> void:
    if follow_target == null:
        return

    var target_pos := follow_target.global_position
    global_position.x = lerp(global_position.x, target_pos.x, delta * horizontal_smooth)
    global_position.y = lerp(global_position.y, target_pos.y, delta * vertical_smooth)
    global_position = _clamp_to_bounds(global_position)
```

Rules:

- follow `Player/CameraAnchor`
- clamp to stage or zone bounds
- boss fights switch to `BOSS_LOCK`
- cutscenes temporarily take camera control
- use light additive shake, not heavy cinematic motion

### Pickups and powerups

Persistent pickups live in the stage scene under `Pickups` or `Capsules`. Temporary drops are spawned at runtime.

Pickup categories:

- health refill
- weapon-energy refill
- heart tank
- sub tank
- armor capsule

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

func collect(receiver: PickupReceiver) -> void:
    receiver.apply_pickup(pickup_data)

    if pickup_data.persistent:
        Progression.mark_pickup_collected(pickup_data.pickup_id)

    queue_free()
```

Persistent pickup rules:

- heart tanks, sub tanks, and armor capsules are persistent
- health and weapon-energy refills are not persistent
- use stable IDs like `intro_highway_dash_capsule` or `storm_eagle_heart_tank`
- stage load should skip already-collected persistent pickups

## Progression, Stage Select, And Save

### Stage select

Use a dedicated scene such as `scenes/ui/stage_select_menu.tscn`.

Rules:

- render a fixed roster from `StageDefinition` resources
- stage order is explicit, not filesystem-derived
- after intro clear, unlock the 8 Maverick stages
- unlock fortress stages only when the required progression flags are set

```gdscript
extends Control

@export var stage_definitions: Array[StageDefinition]

func _ready() -> void:
    for stage_def in stage_definitions:
        _add_stage_card(stage_def, Progression.is_stage_unlocked(stage_def.stage_id))

func _on_stage_selected(stage_id: StringName) -> void:
    GameFlow.request_stage_load(stage_id)
```

### Save system

Initial save format:

- JSON
- versioned
- stored at `user://save_01.json`
- one local save profile in the initial implementation

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

Serialized fields:

- save format version
- boss defeat flags
- weapon unlock flags
- persistent pickup collection IDs
- armor unlock flags
- dash unlock flag
- sub tank ownership and fill values
- intro-clear flag
- fortress-unlock flag

Do not serialize:

- live enemy instances
- temporary pickups
- current checkpoint as a permanent campaign fact
- moment-to-moment HP or weapon energy, unless a suspend-save system is added later

Example payload:

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

### Retry model

For the first implementation:

- retry from checkpoint or stage start
- no full lives/continues system required yet
- lives can be added later on top of this, not inside core movement/combat logic

## Cutscenes And Dialogue

### Cutscenes

Use a data-driven `CutsceneDirector.gd`. Do not hardcode cutscenes inside player scripts.

Use cases:

- intro stage opening
- Zero rescue
- Dr. Light capsule sequences
- boss intro stingers
- stage clear reward flow
- ending and fortress transitions

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

First-pass cutscene actions:

- `move_actor`
- `play_animation_state`
- `camera_pan_to_marker`
- `wait`
- `show_text`
- `emit_audio_event`
- `unlock_dash`
- `end_stage`

### Dialogue

Dialogue is a subsystem used by cutscenes. It should not own progression changes or camera movement.

Files:

- `scenes/ui/dialogue_box.tscn`
- `scripts/ui/dialogue_box.gd`
- `scripts/systems/dialogue_controller.gd`
- `data/dialogue/*.tres` or `data/dialogue/*.json`

```text
DialogueBox.tscn
- DialogueBox (CanvasLayer)
  - Panel
  - SpeakerNameLabel
  - BodyLabel
  - PortraitLeft optional
  - PortraitRight optional
  - AdvanceIndicator
```

```gdscript
class_name DialogueLine
extends Resource

@export var line_id: StringName
@export var speaker_id: StringName
@export_multiline var text: String
@export var portrait_id: StringName
@export var voice_event: StringName
```

```gdscript
class_name DialogueSequence
extends Resource

@export var sequence_id: StringName
@export var lines: Array[DialogueLine]
```

```gdscript
class_name DialogueController
extends Node

signal dialogue_started(sequence_id: StringName)
signal dialogue_finished(sequence_id: StringName)

@onready var dialogue_box: DialogueBox = $DialogueBox

var current_sequence: DialogueSequence
var current_index := -1
var is_active := false

func show_sequence(sequence: DialogueSequence) -> void:
    current_sequence = sequence
    current_index = -1
    is_active = true
    dialogue_started.emit(sequence.sequence_id)
    _advance_line()

func advance() -> void:
    if not is_active:
        return
    _advance_line()

func _advance_line() -> void:
    current_index += 1
    if current_index >= current_sequence.lines.size():
        is_active = false
        dialogue_box.hide_dialogue()
        dialogue_finished.emit(current_sequence.sequence_id)
        return

    var line := current_sequence.lines[current_index]
    dialogue_box.show_line(line)
```

Input rules:

- `menu_confirm` advances dialogue
- `menu_cancel` may skip only skippable sequences
- gameplay input stays disabled while dialogue is active

Capsule flow example:

1. player enters capsule trigger
2. `StageController` starts a cutscene
3. `CutsceneDirector` runs `show_text(dr_light_dash_capsule)`
4. `DialogueController` presents the sequence
5. cutscene executes `unlock_dash`
6. `Progression` marks the capsule collected

## Audio

Audio is event-driven. Gameplay code triggers semantic events, not raw file paths.

Required semantic events:

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

Implementation:

- one autoload: `AudioManager`
- buses: `Master`, `Music`, `SFX`
- data-driven event-to-stream mapping
- missing placeholder clips should fail silently

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

## UI

Required UI:

- title/menu UI
- player HUD
- weapon energy display
- boss health display
- pause menu
- stage select UI
- dialogue box

UI rules:

- UI reads gameplay state
- UI does not own gameplay logic
- stage clear and weapon unlock feedback should use the same UI system

## Placeholder Asset Rules

- use stable placeholder names
- keep collision/hitboxes separate from visuals
- drive visuals from semantic states like `idle`, `run`, `dash`, `hurt`, `charge_small`, `charge_full`
- keep character, enemy, projectile, UI, and stage placeholder conventions consistent

## Milestones

### Phase 1

- project structure
- player movement
- player combat
- shared health/damage/collision
- one enemy family
- boss skeleton
- audio manager
- HUD shell
- one test stage
- standalone stage testing

### Phase 2

- one full vertical slice
- hazards
- checkpoints
- one boss fight
- stage clear flow
- dash unlock flow
- stage-local cutscene
- dialogue flow

### Phase 3

- stage select
- boss weapons
- weaknesses
- armor parts
- heart tanks
- sub tanks
- save/load
- multiple stages
- fortress unlock flow

### Phase 4

- full campaign content
- final Sigma flow
- movement/combat tuning
- placeholder replacement
- bug fixing and optimization

## Acceptance Criteria

- player can run, jump, wall jump, dash, shoot, charge, take damage, die, and respawn
- keyboard and gamepad both work through the same action map
- locomotion and combat state machines run in parallel without conflicts
- pickups and capsules apply effects through `PickupReceiver`
- one stage can be run directly from the editor for mid-level testing
- one stage vertical slice is playable from start to boss clear using placeholders only
- boss defeat updates progression and unlocks the proper weapon reward
- save/load restores persistent campaign state correctly
- audio responds to semantic gameplay events
- dialogue and cutscene flow work without embedding story logic into player scripts

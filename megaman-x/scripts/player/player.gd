extends CharacterBody2D
class_name PlayerController

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

const DEFAULT_TUNING_PATH := "res://data/player/default_player_tuning.tres"

signal locomotion_state_changed(previous_state: int, new_state: int)
signal facing_changed(facing_direction: int)
signal death_sequence_finished

@export var tuning: PlayerTuningData
@export var dash_unlocked := true

@onready var hurtbox: Node = $Hurtbox
@onready var health_component: Node = $HealthComponent
@onready var camera_anchor: Marker2D = $CameraAnchor

var locomotion_state: int = LocomotionState.IDLE
var facing_direction := 1
var _default_gravity := 980.0
var _input_locked := false
var _hurt_timer := 0.0
var _death_timer := 0.0
var _death_notified := false


func _enter_tree() -> void:
	InputDefaults.ensure_default_input_map()


func _ready() -> void:
	if tuning == null:
		tuning = load(DEFAULT_TUNING_PATH) as PlayerTuningData

	_default_gravity = float(ProjectSettings.get_setting("physics/2d/default_gravity"))
	health_component.set("max_health", tuning.base_max_hp)
	health_component.set("invulnerability_duration", tuning.invulnerability_time)
	health_component.set("team", &"player")
	health_component.call("reset")
	health_component.connect("damaged", _on_health_component_damaged)
	health_component.connect("died", _on_health_component_died)
	_set_locomotion_state(LocomotionState.IDLE)


func _physics_process(delta: float) -> void:
	if tuning == null:
		return

	_update_damage_timers(delta)

	var input_axis := 0.0
	if not _input_locked:
		input_axis = Input.get_axis("move_left", "move_right")

	var horizontal_acceleration := tuning.acceleration if is_on_floor() else tuning.air_control
	var horizontal_deceleration := tuning.deceleration if is_on_floor() else tuning.air_control
	var target_speed := input_axis * tuning.run_speed

	if locomotion_state == LocomotionState.DEAD:
		velocity.x = move_toward(velocity.x, 0.0, horizontal_deceleration * delta)
	elif locomotion_state == LocomotionState.HURT:
		velocity.x = move_toward(velocity.x, 0.0, horizontal_deceleration * 0.4 * delta)
	elif absf(input_axis) > 0.01:
		velocity.x = move_toward(velocity.x, target_speed, horizontal_acceleration * delta)
		_set_facing_direction(1 if input_axis > 0.0 else -1)
	else:
		velocity.x = move_toward(velocity.x, 0.0, horizontal_deceleration * delta)

	if not is_on_floor():
		velocity.y += _default_gravity * tuning.gravity_scale * delta
	elif velocity.y > 0.0:
		velocity.y = 0.0

	if not _input_locked and Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = tuning.jump_velocity

	move_and_slide()

	if locomotion_state == LocomotionState.DEAD:
		return

	if _hurt_timer > 0.0:
		_set_locomotion_state(LocomotionState.HURT)
		return

	_update_locomotion_state()


func apply_hit_payload(payload: Dictionary) -> bool:
	return hurtbox.call("apply_hit_payload", payload)


func get_camera_anchor() -> Marker2D:
	return camera_anchor


func get_locomotion_state_name() -> String:
	match locomotion_state:
		LocomotionState.IDLE:
			return "IDLE"
		LocomotionState.RUN:
			return "RUN"
		LocomotionState.JUMP:
			return "JUMP"
		LocomotionState.FALL:
			return "FALL"
		LocomotionState.DASH:
			return "DASH"
		LocomotionState.WALL_SLIDE:
			return "WALL_SLIDE"
		LocomotionState.HURT:
			return "HURT"
		LocomotionState.DEAD:
			return "DEAD"
		_:
			return "UNKNOWN"


func get_facing_name() -> String:
	return "RIGHT" if facing_direction >= 0 else "LEFT"


func get_health_component() -> Node:
	return health_component


func reset_to_spawn(spawn_position: Vector2) -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO
	_input_locked = false
	_hurt_timer = 0.0
	_death_timer = 0.0
	_death_notified = false
	health_component.call("reset")
	_set_locomotion_state(LocomotionState.IDLE)


func _update_locomotion_state() -> void:
	if not is_on_floor():
		if velocity.y < 0.0:
			_set_locomotion_state(LocomotionState.JUMP)
		else:
			_set_locomotion_state(LocomotionState.FALL)
		return

	if absf(velocity.x) > 5.0:
		_set_locomotion_state(LocomotionState.RUN)
	else:
		_set_locomotion_state(LocomotionState.IDLE)


func _set_locomotion_state(new_state: int) -> void:
	if locomotion_state == new_state:
		return

	var previous_state := locomotion_state
	locomotion_state = new_state
	locomotion_state_changed.emit(previous_state, locomotion_state)


func _set_facing_direction(new_facing_direction: int) -> void:
	if facing_direction == new_facing_direction:
		return

	facing_direction = new_facing_direction
	facing_changed.emit(facing_direction)


func _update_damage_timers(delta: float) -> void:
	if _hurt_timer > 0.0:
		_hurt_timer = maxf(_hurt_timer - delta, 0.0)
		if _hurt_timer == 0.0 and locomotion_state != LocomotionState.DEAD:
			_input_locked = false

	if _death_timer > 0.0:
		_death_timer = maxf(_death_timer - delta, 0.0)
		if _death_timer == 0.0 and not _death_notified:
			_death_notified = true
			death_sequence_finished.emit()


func _on_health_component_damaged(payload: Dictionary, _current_health: int) -> void:
	if health_component.get("is_dead"):
		return

	_input_locked = true
	_hurt_timer = tuning.hurt_duration
	var knockback: Vector2 = payload.get("knockback", Vector2.ZERO)
	velocity = knockback
	_set_locomotion_state(LocomotionState.HURT)
	if knockback.x != 0.0:
		_set_facing_direction(1 if knockback.x > 0.0 else -1)


func _on_health_component_died() -> void:
	_input_locked = true
	_hurt_timer = 0.0
	_death_timer = tuning.death_delay
	_death_notified = false
	velocity = Vector2.ZERO
	_set_locomotion_state(LocomotionState.DEAD)

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
signal dash_unlocked_changed(is_unlocked: bool)
signal death_sequence_finished

@export var tuning: PlayerTuningData
@export var dash_unlocked := true

@onready var hurtbox: Node = $Hurtbox
@onready var health_component: Node = $HealthComponent
@onready var player_combat: PlayerCombat = $PlayerCombat as PlayerCombat
@onready var pickup_receiver: PickupReceiver = $PickupReceiver as PickupReceiver
@onready var player_sensor: Area2D = $PlayerSensor
@onready var camera_anchor: Marker2D = $CameraAnchor
@onready var wall_check_left: RayCast2D = $WallCheckLeft
@onready var wall_check_right: RayCast2D = $WallCheckRight

var locomotion_state: int = LocomotionState.IDLE
var facing_direction := 1
var _default_gravity := 980.0
var _input_locked := false
var _gameplay_enabled := true
var _hurt_timer := 0.0
var _death_timer := 0.0
var _death_notified := false
var _dash_timer := 0.0


func _enter_tree() -> void:
	InputDefaults.ensure_default_input_map()


func _ready() -> void:
	if tuning == null:
		tuning = load(DEFAULT_TUNING_PATH) as PlayerTuningData

	_default_gravity = float(ProjectSettings.get_setting("physics/2d/default_gravity"))
	health_component.set("invulnerability_duration", tuning.invulnerability_time)
	health_component.set("team", &"player")
	var progression := _get_progression()
	if progression != null and progression.has_signal("progression_changed"):
		progression.progression_changed.connect(_on_progression_changed)
	apply_progression_upgrades(true)
	health_component.connect("damaged", _on_health_component_damaged)
	health_component.connect("died", _on_health_component_died)
	if player_sensor != null:
		player_sensor.area_entered.connect(_on_player_sensor_area_entered)
	_set_locomotion_state(LocomotionState.IDLE)


func _physics_process(delta: float) -> void:
	if tuning == null:
		return

	_update_damage_timers(delta)
	_update_dash_timer(delta)

	var input_axis := 0.0
	if not _input_locked and _gameplay_enabled:
		input_axis = Input.get_axis("move_left", "move_right")

	if absf(input_axis) > 0.01 and _dash_timer == 0.0:
		_set_facing_direction(1 if input_axis > 0.0 else -1)

	if _can_start_dash():
		_start_dash()

	var wall_contact_direction := _get_wall_contact_direction()
	var wall_slide_active := _is_wall_slide_active(input_axis, wall_contact_direction)
	if wall_slide_active and not is_on_floor() and Input.is_action_just_pressed("jump"):
		_start_wall_jump(wall_contact_direction)
		wall_contact_direction = 0
		wall_slide_active = false

	var horizontal_acceleration := tuning.acceleration if is_on_floor() else tuning.air_control
	var horizontal_deceleration := tuning.deceleration if is_on_floor() else tuning.air_control
	var target_speed := input_axis * tuning.run_speed

	if locomotion_state == LocomotionState.DEAD:
		velocity.x = move_toward(velocity.x, 0.0, horizontal_deceleration * delta)
	elif locomotion_state == LocomotionState.HURT:
		velocity.x = move_toward(velocity.x, 0.0, horizontal_deceleration * 0.4 * delta)
	elif _dash_timer > 0.0:
		velocity.x = float(facing_direction) * tuning.dash_speed
	elif wall_slide_active and _is_pressing_into_wall(input_axis, wall_contact_direction):
		velocity.x = 0.0
	elif absf(input_axis) > 0.01:
		velocity.x = move_toward(velocity.x, target_speed, horizontal_acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, horizontal_deceleration * delta)

	if not is_on_floor():
		velocity.y += _default_gravity * tuning.gravity_scale * delta
	elif velocity.y > 0.0:
		velocity.y = 0.0

	if not _input_locked and _gameplay_enabled and Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = tuning.jump_velocity

	if wall_slide_active:
		velocity.y = minf(velocity.y, tuning.wall_slide_speed)

	if not _input_locked and _gameplay_enabled and Input.is_action_just_pressed("sub_tank_use") and pickup_receiver != null:
		pickup_receiver.use_sub_tank()

	move_and_slide()

	if locomotion_state == LocomotionState.DEAD:
		return

	if _hurt_timer > 0.0:
		_set_locomotion_state(LocomotionState.HURT)
		return

	_update_locomotion_state(input_axis)


func apply_hit_payload(payload: Dictionary) -> bool:
	if payload == null:
		return false

	var adjusted_payload := payload
	var progression := _get_progression()
	if progression != null and progression.has_method("has_armor_part") and progression.has_armor_part(&"body"):
		adjusted_payload = payload.duplicate(true)
		adjusted_payload["damage"] = maxi(1, int(payload.get("damage", 0)) - 1)

	return hurtbox.call("apply_hit_payload", adjusted_payload)


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


func get_player_combat() -> PlayerCombat:
	return player_combat


func is_dash_unlocked() -> bool:
	return dash_unlocked


func set_dash_unlocked(is_unlocked: bool) -> void:
	if dash_unlocked == is_unlocked:
		return

	dash_unlocked = is_unlocked
	if not dash_unlocked:
		_dash_timer = 0.0
	dash_unlocked_changed.emit(dash_unlocked)


func is_gameplay_enabled() -> bool:
	return _gameplay_enabled


func set_gameplay_enabled(is_enabled: bool, _reason: StringName = &"") -> void:
	_gameplay_enabled = is_enabled
	if not _gameplay_enabled:
		_input_locked = true
		_dash_timer = 0.0
		if player_combat != null:
			player_combat.set_combat_enabled(false, &"gameplay_disabled")
	else:
		if locomotion_state != LocomotionState.DEAD and _hurt_timer == 0.0:
			_input_locked = false
			if player_combat != null:
				player_combat.set_combat_enabled(true, &"gameplay_enabled")


func reset_to_spawn(spawn_position: Vector2) -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO
	_gameplay_enabled = true
	_input_locked = false
	_hurt_timer = 0.0
	_death_timer = 0.0
	_death_notified = false
	_dash_timer = 0.0
	apply_progression_upgrades(true)
	if player_combat != null:
		player_combat.reset_combat()
	_set_locomotion_state(LocomotionState.IDLE)


func apply_progression_upgrades(fill_to_full := false) -> void:
	if tuning == null or health_component == null:
		return

	var desired_max_health := tuning.base_max_hp
	var progression := _get_progression()
	if progression != null and progression.has_method("get_heart_tank_health_bonus"):
		desired_max_health += int(progression.get_heart_tank_health_bonus())

	var previous_max_health := int(health_component.get("max_health"))
	health_component.set("invulnerability_duration", tuning.invulnerability_time)
	if health_component.has_method("set_max_health_value"):
		health_component.set_max_health_value(
			desired_max_health,
			fill_to_full,
			maxi(desired_max_health - previous_max_health, 0)
		)
	elif fill_to_full:
		health_component.set("max_health", desired_max_health)
		health_component.call("reset")
	else:
		health_component.set("max_health", desired_max_health)


func _get_progression() -> Node:
	return get_node_or_null("/root/Progression")


func _update_locomotion_state(input_axis: float) -> void:
	if _dash_timer > 0.0 and is_on_floor():
		_set_locomotion_state(LocomotionState.DASH)
		return

	if _is_wall_slide_active(input_axis, _get_wall_contact_direction()):
		_set_locomotion_state(LocomotionState.WALL_SLIDE)
		return

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
			_input_locked = not _gameplay_enabled
			if player_combat != null and _gameplay_enabled:
				player_combat.set_combat_enabled(true, &"recovered")

	if _death_timer > 0.0:
		_death_timer = maxf(_death_timer - delta, 0.0)
		if _death_timer == 0.0 and not _death_notified:
			_death_notified = true
			death_sequence_finished.emit()


func _update_dash_timer(delta: float) -> void:
	if _dash_timer <= 0.0:
		return

	_dash_timer = maxf(_dash_timer - delta, 0.0)


func _get_wall_contact_direction() -> int:
	if wall_check_left != null:
		wall_check_left.force_raycast_update()
	if wall_check_right != null:
		wall_check_right.force_raycast_update()

	var left_colliding := wall_check_left != null and wall_check_left.is_colliding()
	var right_colliding := wall_check_right != null and wall_check_right.is_colliding()
	if left_colliding == right_colliding:
		return 0

	return -1 if left_colliding else 1


func _is_pressing_into_wall(input_axis: float, wall_contact_direction: int) -> bool:
	if wall_contact_direction == 0:
		return false

	return input_axis < -0.01 if wall_contact_direction < 0 else input_axis > 0.01


func _is_wall_slide_active(input_axis: float, wall_contact_direction: int) -> bool:
	return wall_contact_direction != 0 \
		and not is_on_floor() \
		and velocity.y >= 0.0 \
		and _dash_timer == 0.0 \
		and locomotion_state != LocomotionState.DEAD \
		and locomotion_state != LocomotionState.HURT \
		and _gameplay_enabled \
		and not _input_locked \
		and _is_pressing_into_wall(input_axis, wall_contact_direction)


func _start_wall_jump(wall_contact_direction: int) -> void:
	if wall_contact_direction == 0:
		return

	velocity = Vector2(absf(tuning.wall_jump_force.x) * float(-wall_contact_direction), tuning.wall_jump_force.y)
	_set_facing_direction(-wall_contact_direction)
	_set_locomotion_state(LocomotionState.JUMP)


func _can_start_dash() -> bool:
	return dash_unlocked \
		and _dash_timer == 0.0 \
		and not _input_locked \
		and _gameplay_enabled \
		and locomotion_state != LocomotionState.DEAD \
		and locomotion_state != LocomotionState.HURT \
		and is_on_floor() \
		and Input.is_action_just_pressed("dash")


func _start_dash() -> void:
	_dash_timer = tuning.dash_duration
	velocity.x = float(facing_direction) * tuning.dash_speed
	_set_locomotion_state(LocomotionState.DASH)


func _on_health_component_damaged(payload: Dictionary, _current_health: int) -> void:
	if health_component.get("is_dead"):
		return

	_input_locked = true
	_hurt_timer = tuning.hurt_duration
	_dash_timer = 0.0
	var knockback: Vector2 = payload.get("knockback", Vector2.ZERO)
	velocity = knockback
	if player_combat != null:
		player_combat.set_combat_enabled(false, &"hurt")
	_play_audio_event(&"player_hurt")
	_set_locomotion_state(LocomotionState.HURT)
	if knockback.x != 0.0:
		_set_facing_direction(1 if knockback.x > 0.0 else -1)


func _on_health_component_died() -> void:
	_input_locked = true
	_hurt_timer = 0.0
	_death_timer = tuning.death_delay
	_death_notified = false
	_dash_timer = 0.0
	velocity = Vector2.ZERO
	if player_combat != null:
		player_combat.set_combat_enabled(false, &"dead")
	_set_locomotion_state(LocomotionState.DEAD)


func _play_audio_event(event_id: StringName) -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null:
		audio_manager.play_sfx(event_id)


func _on_progression_changed() -> void:
	apply_progression_upgrades(false)


func _on_player_sensor_area_entered(area: Area2D) -> void:
	if pickup_receiver == null or area == null:
		return

	pickup_receiver.apply_pickup(area)

extends CharacterBody2D

const STOMP_COMBO_POINTS := [100, 200, 400, 500, 800, 1000, 2000, 4000, 5000, 8000]
const FireballScene := preload("res://scenes/objects/fireball.tscn")

const STAR_POWER_DURATION: float = 10.0
const STAR_WARNING_TIME: float = 2.0
const MAX_FIREBALLS: int = 2

@export var movement: Resource  # PlayerMovementConfig
@export var cam_config: Resource  # CameraConfig
@export var effects: Resource  # EffectsConfig

var coyote_active: bool = false
var jump_buffered: bool = false

var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _is_crouching: bool = false
var _is_invincible: bool = false
var _invincibility_timer: float = 0.0
var _stomp_combo: int = 0

# Star power
var _is_star_powered: bool = false
var _star_timer: float = 0.0

# Fireball tracking
var _active_fireballs: int = 0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visuals: Node2D = $Visuals
@onready var drawer: Node2D = $Visuals/PlayerDrawer
@onready var state_machine: Node = $StateMachine
@onready var camera: Camera2D = $Camera2D
@onready var stomp_detector: Area2D = $StompDetector
@onready var hurtbox: Area2D = $Hurtbox


var _camera_look_ahead: float = 0.0
var _max_camera_x: float = 0.0


func _ready() -> void:
	add_to_group("player")
	CameraEffects.register_camera(camera)
	stomp_detector.area_entered.connect(_on_stomp_area_entered)
	hurtbox.area_entered.connect(_on_hurtbox_area_entered)


func _process(delta: float) -> void:
	# Coyote timer
	if _coyote_timer > 0.0:
		_coyote_timer -= delta
		if _coyote_timer <= 0.0:
			coyote_active = false

	# Jump buffer timer
	if _jump_buffer_timer > 0.0:
		_jump_buffer_timer -= delta
		if _jump_buffer_timer <= 0.0:
			jump_buffered = false

	# Camera look-ahead and no-backtrack
	var target_ahead: float = signf(visuals.scale.x) * cam_config.look_ahead_distance
	_camera_look_ahead = move_toward(_camera_look_ahead, target_ahead, cam_config.look_ahead_speed * delta)
	var shake := CameraEffects.get_shake_offset()
	camera.offset.x = _camera_look_ahead + shake.x
	camera.offset.y = shake.y

	# Prevent camera from scrolling left (no backtracking)
	var cam_left: float = global_position.x + _camera_look_ahead - cam_config.no_backtrack_offset
	if cam_left > _max_camera_x:
		_max_camera_x = cam_left
	camera.limit_left = int(_max_camera_x)

	# Stomp combo resets on ground
	if is_on_floor():
		_stomp_combo = 0

	# Invincibility flash (damage-based)
	if _is_invincible and not _is_star_powered:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0.0:
			_is_invincible = false
			modulate.a = 1.0
		else:
			modulate.a = 0.3 if fmod(_invincibility_timer, 0.15) < 0.075 else 1.0

	# Star power
	if _is_star_powered:
		_star_timer -= delta
		# Palette cycling
		drawer.star_power_active = true
		# Warning flashes in last 2 seconds
		if _star_timer <= STAR_WARNING_TIME:
			modulate.a = 0.5 if fmod(_star_timer, 0.2) < 0.1 else 1.0
		if _star_timer <= 0.0:
			_end_star_power()

	# Fireball input (Fire Mario, run button, any normal gameplay state)
	_check_fireball_input()


func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		var grav: float = movement.gravity
		if velocity.y > 0.0:
			grav = movement.fast_fall_gravity
		velocity.y = minf(velocity.y + grav * delta, movement.max_fall_speed)


func check_ceiling_bumps() -> void:
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		if col.get_normal().y > 0.5:
			var collider := col.get_collider()
			if collider and collider.has_method("bump_from_below"):
				collider.bump_from_below()


func apply_movement(direction: float, delta: float) -> void:
	var is_running := Input.is_action_pressed(&"run")
	var max_speed: float = movement.run_speed if is_running else movement.walk_speed

	var is_turning := direction * velocity.x < 0.0 and absf(velocity.x) > 30.0
	var accel: float = movement.turn_acceleration if is_turning else movement.acceleration

	velocity.x = move_toward(velocity.x, direction * max_speed, accel * delta)
	move_and_slide()


func apply_air_movement(direction: float, delta: float) -> void:
	var is_running := Input.is_action_pressed(&"run")
	var max_speed: float = movement.run_speed if is_running else movement.walk_speed
	velocity.x = move_toward(velocity.x, direction * max_speed, movement.air_acceleration * delta)


func apply_deceleration(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, movement.deceleration * delta)
	move_and_slide()


func update_facing(direction: float) -> void:
	if direction > 0.0:
		visuals.scale.x = 1.0
	elif direction < 0.0:
		visuals.scale.x = -1.0


func start_coyote_timer() -> void:
	coyote_active = true
	_coyote_timer = movement.coyote_time


func buffer_jump() -> void:
	jump_buffered = true
	_jump_buffer_timer = movement.jump_buffer_time


func can_crouch() -> bool:
	return GameManager.current_power_state != GameManager.PowerState.SMALL


func set_crouching(crouching: bool) -> void:
	_is_crouching = crouching
	drawer.is_crouching = crouching
	_update_collision_shape()


func has_ceiling_clearance() -> bool:
	if GameManager.current_power_state == GameManager.PowerState.SMALL:
		return true
	var space := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(
		global_position + Vector2(0, -movement.small_collision.y),
		global_position + Vector2(0, -movement.big_collision.y - 2.0),
		collision_mask,
	)
	query.exclude = [get_rid()]
	var result := space.intersect_ray(query)
	return result.is_empty()


func die() -> void:
	if _is_star_powered:
		_end_star_power()
	stomp_detector.set_deferred("monitoring", false)
	hurtbox.set_deferred("monitoring", false)
	hurtbox.set_deferred("monitorable", false)
	state_machine.transition_to(&"DeathState")
	EventBus.player_died.emit()


func power_up(item_type: StringName, _position: Vector2 = Vector2.ZERO) -> void:
	if item_type == &"starman":
		GameManager.add_score(1000, global_position)
		_start_star_power()
		return

	var current := GameManager.current_power_state
	var new_state: int = current
	match item_type:
		&"mushroom":
			if current == GameManager.PowerState.SMALL:
				new_state = GameManager.PowerState.BIG
		&"fire_flower":
			if current == GameManager.PowerState.SMALL:
				new_state = GameManager.PowerState.BIG
			else:
				new_state = GameManager.PowerState.FIRE

	if new_state == current:
		GameManager.add_score(1000, global_position)
		return

	GameManager.set_power_state(new_state)
	GameManager.add_score(1000, global_position)
	state_machine.transition_to(&"GrowState")


func take_damage() -> void:
	if _is_invincible:
		return
	if GameManager.current_power_state == GameManager.PowerState.SMALL:
		die()
	else:
		GameManager.set_power_state(GameManager.PowerState.SMALL)
		state_machine.transition_to(&"ShrinkState")


func _start_invincibility() -> void:
	_is_invincible = true
	_invincibility_timer = movement.invincibility_duration


func _on_stomp_area_entered(area: Area2D) -> void:
	if velocity.y <= 0.0:
		return
	var enemy := area.get_parent()
	if not is_instance_valid(enemy) or not enemy.has_method("stomp_kill"):
		return
	var was_killed: bool = enemy.stomp_kill()
	if was_killed:
		var points: int
		if _stomp_combo < STOMP_COMBO_POINTS.size():
			points = STOMP_COMBO_POINTS[_stomp_combo]
		else:
			points = 0
			GameManager.lives += 1
			EventBus.one_up_earned.emit()
			EventBus.lives_changed.emit(GameManager.lives)
		if points > 0:
			GameManager.add_score(points, enemy.global_position)
		_stomp_combo += 1
	velocity.y = movement.stomp_bounce_velocity


func _on_hurtbox_area_entered(area: Area2D) -> void:
	var enemy := area.get_parent()
	if not is_instance_valid(enemy):
		return
	# Star power kills enemies on contact
	if _is_star_powered:
		if enemy.has_method("is_dangerous") and enemy.is_dangerous():
			if enemy.has_method("non_stomp_kill"):
				enemy.non_stomp_kill()
			elif enemy.has_method("shell_kill"):
				enemy.shell_kill()
		return
	if _is_invincible:
		return
	if velocity.y > 0.0 and global_position.y + 2.0 < enemy.global_position.y:
		return
	if enemy.has_method("try_kick"):
		var kick_dir := signf(enemy.global_position.x - global_position.x)
		if kick_dir == 0.0:
			kick_dir = signf(visuals.scale.x)
		if enemy.try_kick(kick_dir):
			return
	if enemy.has_method("is_dangerous") and enemy.is_dangerous():
		take_damage()


func _update_collision_shape() -> void:
	var shape := collision_shape.shape as RectangleShape2D
	if _is_crouching or GameManager.current_power_state == GameManager.PowerState.SMALL:
		shape.size = movement.small_collision
		collision_shape.position.y = -movement.small_collision.y / 2.0
	else:
		shape.size = movement.big_collision
		collision_shape.position.y = -movement.big_collision.y / 2.0
	drawer.power_state = GameManager.current_power_state


# --- Star Power ---

func _start_star_power() -> void:
	_is_star_powered = true
	_is_invincible = true
	_star_timer = STAR_POWER_DURATION
	drawer.star_power_active = true
	EventBus.player_star_power_started.emit()
	AudioManager.play_music(&"star")


func _end_star_power() -> void:
	_is_star_powered = false
	_star_timer = 0.0
	modulate.a = 1.0
	drawer.star_power_active = false
	# Restore damage invincibility if not already expired
	if _invincibility_timer <= 0.0:
		_is_invincible = false
	EventBus.player_star_power_ended.emit()
	AudioManager.play_music(&"overworld")


# --- Fireballs ---

func _check_fireball_input() -> void:
	if GameManager.current_power_state != GameManager.PowerState.FIRE:
		return
	if _active_fireballs >= MAX_FIREBALLS:
		return
	# Don't shoot during special states
	var current_state_name: StringName = state_machine.current_state.name
	if current_state_name in [&"DeathState", &"GrowState", &"ShrinkState", &"PipeEnterState", &"FlagpoleState"]:
		return
	if Input.is_action_just_pressed(&"run"):
		_spawn_fireball()


func _spawn_fireball() -> void:
	var fireball := FireballScene.instantiate() as CharacterBody2D
	var dir: float = signf(visuals.scale.x)
	if dir == 0.0:
		dir = 1.0
	fireball.setup(dir)
	get_parent().add_child(fireball)
	fireball.global_position = global_position + Vector2(dir * 10.0, -10.0)
	_active_fireballs += 1
	fireball.tree_exited.connect(func() -> void: _active_fireballs -= 1)
	AudioManager.play_sfx(&"fireball")


# --- Pipe Entry ---

func enter_pipe(pipe: Node2D, target: Node2D) -> void:
	var pipe_state := state_machine.get_node(NodePath("PipeEnterState"))
	if pipe_state and pipe_state.has_method("setup"):
		pipe_state.setup(pipe, target)
		state_machine.transition_to(&"PipeEnterState")


# --- Flagpole ---

func start_flagpole(flagpole: Node2D) -> void:
	var fp_state := state_machine.get_node(NodePath("FlagpoleState"))
	if fp_state and fp_state.has_method("setup"):
		fp_state.setup(flagpole)
		state_machine.transition_to(&"FlagpoleState")

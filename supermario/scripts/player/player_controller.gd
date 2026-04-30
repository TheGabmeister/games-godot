extends CharacterBody2D

const STOMP_COMBO_POINTS := [100, 200, 400, 500, 800, 1000, 2000, 4000, 5000, 8000]
const FireballScene := preload("res://scenes/objects/fireball.tscn")
const StateIds := preload("res://scripts/player/player_state_ids.gd")
const SpriteHelper := preload("res://scripts/visuals/sprite_region_helper.gd")

const STAR_POWER_DURATION: float = 10.0
const STAR_WARNING_TIME: float = 2.0
const MAX_FIREBALLS: int = 2
const VISUAL_SCALE: float = 2.0
const SHEET_COLUMNS := 6
const SPRITE_OFFSET := Vector2(-16, -30)

@export var movement: Resource  # PlayerMovementConfig
@export var effects: Resource  # EffectsConfig
@export var jump_sound: AudioStream
@export var jump_big_sound: AudioStream
@export var powerup_sound: AudioStream
@export var powerdown_sound: AudioStream
@export var death_sound: AudioStream
@export var fireball_sound: AudioStream
@export var star_music: AudioStream

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

# Sprite animation
# `displayed_power_state` is normally synced to GameManager.current_power_state in
# update_collision_shape(), but GrowState / ShrinkState override it during the
# flicker animation so the sprite alternates between Small and Big frames while
# the actual power transition is locked in.
var displayed_power_state: int = 0
var _walk_cycle: float = 0.0
var _star_cycle: float = 0.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visuals: Node2D = $Visuals
@onready var _sprite: Sprite2D = $Visuals/Sprite
@onready var state_machine: Node = $StateMachine
@onready var camera: Camera2D = $Camera2D
@onready var stomp_detector: Area2D = $StompDetector
@onready var hurtbox: Area2D = $Hurtbox


func _ready() -> void:
	add_to_group("player")
	stomp_detector.area_entered.connect(_on_stomp_area_entered)
	hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	EventBus.player_powered_up.connect(_on_player_powered_up)
	EventBus.player_damaged.connect(_on_player_damaged)
	# Sync collision size with the current GameManager power state. Required
	# because power is preserved across level transitions (e.g., finishing 1-1
	# as Fire Mario should spawn Fire Mario in 1-2), but the scene file bakes
	# in the Small collision.
	update_collision_shape()


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
		# Warning flashes in last 2 seconds
		if _star_timer <= STAR_WARNING_TIME:
			modulate.a = 0.5 if fmod(_star_timer, 0.2) < 0.1 else 1.0
		if _star_timer <= 0.0:
			_end_star_power()

	# Fireball input (Fire Mario, run button, any normal gameplay state)
	_check_fireball_input()

	_update_sprite_frame(delta)


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


func apply_air_movement(direction: float, delta: float) -> void:
	var is_running := Input.is_action_pressed(&"run")
	var max_speed: float = movement.run_speed if is_running else movement.walk_speed
	velocity.x = move_toward(velocity.x, direction * max_speed, movement.air_acceleration * delta)


func apply_deceleration(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, movement.deceleration * delta)


func update_facing(direction: float) -> void:
	if direction > 0.0:
		visuals.scale = Vector2(VISUAL_SCALE, VISUAL_SCALE)
	elif direction < 0.0:
		visuals.scale = Vector2(-VISUAL_SCALE, VISUAL_SCALE)


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
	update_collision_shape()


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
	_play_sound(death_sound)
	stomp_detector.set_deferred("monitoring", false)
	hurtbox.set_deferred("monitoring", false)
	hurtbox.set_deferred("monitorable", false)
	state_machine.transition_to(StateIds.DEATH)
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
	state_machine.transition_to(StateIds.GROW)


func take_damage() -> void:
	if _is_invincible:
		return
	if GameManager.current_power_state == GameManager.PowerState.SMALL:
		die()
	else:
		GameManager.set_power_state(GameManager.PowerState.SMALL)
		state_machine.transition_to(StateIds.SHRINK)


func start_invincibility() -> void:
	_is_invincible = true
	_invincibility_timer = movement.invincibility_duration


func play_jump_sound() -> void:
	if GameManager.current_power_state == GameManager.PowerState.SMALL or jump_big_sound == null:
		_play_sound(jump_sound)
	else:
		_play_sound(jump_big_sound)


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
			GameManager.earn_one_up()
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
	# Skip damage if this looks like a stomp — unless the enemy can't be stomped
	var stompable: bool = not (enemy.has_method("is_stompable") and not enemy.is_stompable())
	if stompable and velocity.y > 0.0 and global_position.y + 2.0 < enemy.global_position.y:
		return
	if enemy.has_method("try_kick"):
		var kick_dir := signf(enemy.global_position.x - global_position.x)
		if kick_dir == 0.0:
			kick_dir = signf(visuals.scale.x)
		if enemy.try_kick(kick_dir):
			return
	if enemy.has_method("is_dangerous") and enemy.is_dangerous():
		take_damage()


func update_collision_shape() -> void:
	var shape := collision_shape.shape as RectangleShape2D
	if _is_crouching or GameManager.current_power_state == GameManager.PowerState.SMALL:
		shape.size = movement.small_collision
		collision_shape.position.y = -movement.small_collision.y / 2.0
	else:
		shape.size = movement.big_collision
		collision_shape.position.y = -movement.big_collision.y / 2.0
	displayed_power_state = GameManager.current_power_state


# --- Star Power ---

func _start_star_power() -> void:
	_is_star_powered = true
	_is_invincible = true
	_star_timer = STAR_POWER_DURATION
	EventBus.player_star_power_started.emit()
	EventBus.music_requested.emit(star_music)


func _end_star_power() -> void:
	_is_star_powered = false
	_star_timer = 0.0
	modulate.a = 1.0
	# Restore damage invincibility if not already expired
	if _invincibility_timer <= 0.0:
		_is_invincible = false
	EventBus.player_star_power_ended.emit()
	EventBus.level_music_requested.emit()


# --- Sprite Animation ---

func _update_sprite_frame(delta: float) -> void:
	var is_moving := absf(velocity.x) > 10.0
	if is_moving:
		_walk_cycle += absf(velocity.x) * delta * 0.05
	else:
		_walk_cycle = 0.0

	if _is_star_powered:
		_star_cycle += delta * 8.0
		_sprite.modulate = _star_color()
	else:
		_sprite.modulate = Color.WHITE

	SpriteHelper.set_cell(_sprite, _get_frame_index(is_moving), SHEET_COLUMNS, SPRITE_OFFSET)


func _get_frame_index(is_moving: bool) -> int:
	var current_state: Node = state_machine.current_state
	var state_name: StringName = current_state.name if current_state else &""
	var power_state := displayed_power_state

	if power_state == GameManager.PowerState.SMALL:
		if state_name == StateIds.DEATH:
			return 4
		if state_name == StateIds.JUMP or state_name == StateIds.FALL:
			return 3
		if is_moving:
			return 1 + (int(_walk_cycle * 8.0) % 2)
		return 0

	var base := 11 if power_state == GameManager.PowerState.FIRE else 5
	if _is_crouching:
		return base + 4
	if state_name == StateIds.FLAGPOLE:
		return base + 5
	if state_name == StateIds.JUMP or state_name == StateIds.FALL:
		return base + 3
	if is_moving:
		return base + 1 + (int(_walk_cycle * 8.0) % 2)
	return base


func _star_color() -> Color:
	match int(_star_cycle) % 4:
		0:
			return Color(1.0, 1.0, 0.5)
		1:
			return Color(1.0, 0.55, 0.55)
		2:
			return Color(0.55, 1.0, 0.65)
		_:
			return Color(0.75, 0.9, 1.0)


# --- Fireballs ---

func _check_fireball_input() -> void:
	if GameManager.current_power_state != GameManager.PowerState.FIRE:
		return
	if _active_fireballs >= MAX_FIREBALLS:
		return
	# Don't shoot during special states
	var current_state_name: StringName = state_machine.current_state.name
	if current_state_name in [
		StateIds.DEATH,
		StateIds.GROW,
		StateIds.SHRINK,
		StateIds.PIPE_ENTER,
		StateIds.FLAGPOLE,
	]:
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
	fireball.global_position = global_position + Vector2(dir * 20.0, -20.0)
	_active_fireballs += 1
	fireball.tree_exited.connect(func() -> void: _active_fireballs -= 1)
	_play_sound(fireball_sound)


# --- Pipe Entry ---

func enter_pipe(pipe: Node2D, target: Node2D) -> void:
	var pipe_state := state_machine.get_node(NodePath(StateIds.PIPE_ENTER))
	if pipe_state and pipe_state.has_method("setup"):
		pipe_state.setup(pipe, target)
		state_machine.transition_to(StateIds.PIPE_ENTER)


# --- Flagpole ---

func start_flagpole(flagpole: Node2D) -> void:
	var fp_state := state_machine.get_node(NodePath(StateIds.FLAGPOLE))
	if fp_state and fp_state.has_method("setup"):
		fp_state.setup(flagpole)
		state_machine.transition_to(StateIds.FLAGPOLE)


func _on_player_powered_up(_power_up_type: StringName) -> void:
	_play_sound(powerup_sound)


func _on_player_damaged() -> void:
	_play_sound(powerdown_sound)


func _play_sound(sound: AudioStream) -> void:
	if sound != null:
		EventBus.sfx_requested.emit(sound)

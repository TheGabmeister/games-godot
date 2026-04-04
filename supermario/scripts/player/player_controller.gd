extends CharacterBody2D

# Physics constants
const WALK_SPEED        := 130.0
const RUN_SPEED         := 210.0
const ACCELERATION      := 800.0
const DECELERATION      := 1200.0
const AIR_ACCELERATION  := 600.0
const TURN_ACCELERATION := 1600.0
const JUMP_VELOCITY     := -330.0
const JUMP_RELEASE_MULT := 0.5
const GRAVITY           := 900.0
const FAST_FALL_GRAVITY := 1400.0
const MAX_FALL_SPEED    := 500.0
const COYOTE_TIME       := 0.08
const JUMP_BUFFER_TIME  := 0.10

const SMALL_COLLISION := Vector2(12.0, 14.0)
const BIG_COLLISION   := Vector2(12.0, 28.0)

var coyote_active: bool = false
var jump_buffered: bool = false

var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _is_crouching: bool = false

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visuals: Node2D = $Visuals
@onready var drawer: Node2D = $Visuals/PlayerDrawer
@onready var state_machine: Node = $StateMachine
@onready var camera: Camera2D = $Camera2D


var _camera_look_ahead: float = 0.0
var _max_camera_x: float = 0.0


func _ready() -> void:
	add_to_group("player")
	CameraEffects.register_camera(camera)


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
	var target_ahead := signf(visuals.scale.x) * 24.0
	_camera_look_ahead = move_toward(_camera_look_ahead, target_ahead, 80.0 * delta)
	camera.offset.x = _camera_look_ahead

	# Prevent camera from scrolling left (no backtracking)
	var cam_left := global_position.x + camera.offset.x - 256.0
	if cam_left > _max_camera_x:
		_max_camera_x = cam_left
	camera.limit_left = int(_max_camera_x)


func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		var grav := GRAVITY
		if velocity.y > 0.0:
			grav = FAST_FALL_GRAVITY
		velocity.y = minf(velocity.y + grav * delta, MAX_FALL_SPEED)


func check_ceiling_bumps() -> void:
	# Iterate slide collisions from the last move_and_slide and bump any
	# blocks whose underside we hit with our head.
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		if col.get_normal().y > 0.5:  # normal points down → we hit a ceiling
			var collider := col.get_collider()
			if collider and collider.has_method("bump_from_below"):
				collider.bump_from_below()


func apply_movement(direction: float, delta: float) -> void:
	var is_running := Input.is_action_pressed(&"run")
	var max_speed := RUN_SPEED if is_running else WALK_SPEED

	# Check if turning (skid)
	var is_turning := direction * velocity.x < 0.0 and absf(velocity.x) > 30.0
	var accel := TURN_ACCELERATION if is_turning else ACCELERATION

	velocity.x = move_toward(velocity.x, direction * max_speed, accel * delta)
	move_and_slide()


func apply_air_movement(direction: float, delta: float) -> void:
	var is_running := Input.is_action_pressed(&"run")
	var max_speed := RUN_SPEED if is_running else WALK_SPEED
	velocity.x = move_toward(velocity.x, direction * max_speed, AIR_ACCELERATION * delta)


func apply_deceleration(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, DECELERATION * delta)
	move_and_slide()


func update_facing(direction: float) -> void:
	if direction > 0.0:
		visuals.scale.x = 1.0
	elif direction < 0.0:
		visuals.scale.x = -1.0


func start_coyote_timer() -> void:
	coyote_active = true
	_coyote_timer = COYOTE_TIME


func buffer_jump() -> void:
	jump_buffered = true
	_jump_buffer_timer = JUMP_BUFFER_TIME


func can_crouch() -> bool:
	return GameManager.current_power_state != GameManager.PowerState.SMALL


func set_crouching(crouching: bool) -> void:
	_is_crouching = crouching
	drawer.is_crouching = crouching
	_update_collision_shape()


func has_ceiling_clearance() -> bool:
	if GameManager.current_power_state == GameManager.PowerState.SMALL:
		return true
	# Cast upward to check for ceiling
	var space := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(
		global_position + Vector2(0, -SMALL_COLLISION.y),
		global_position + Vector2(0, -BIG_COLLISION.y - 2.0),
		collision_mask,
	)
	query.exclude = [get_rid()]
	var result := space.intersect_ray(query)
	return result.is_empty()


func die() -> void:
	state_machine.transition_to(&"DeathState")
	EventBus.player_died.emit()


func power_up(item_type: StringName, _position: Vector2 = Vector2.ZERO) -> void:
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
		# Already at max — just award points
		GameManager.add_score(1000, global_position)
		return

	GameManager.set_power_state(new_state)
	GameManager.add_score(1000, global_position)
	_update_collision_shape()
	# Small upward nudge so the bigger collision shape doesn't clip into ground
	global_position.y -= 1.0


func _update_collision_shape() -> void:
	var shape := collision_shape.shape as RectangleShape2D
	if _is_crouching or GameManager.current_power_state == GameManager.PowerState.SMALL:
		shape.size = SMALL_COLLISION
		collision_shape.position.y = -SMALL_COLLISION.y / 2.0
	else:
		shape.size = BIG_COLLISION
		collision_shape.position.y = -BIG_COLLISION.y / 2.0
	drawer.power_state = GameManager.current_power_state

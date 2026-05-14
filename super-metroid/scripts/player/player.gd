class_name Player
extends CharacterBody2D

@export var gravity: float = 900.0
@export var walk_speed: float = 130.0
@export var run_speed: float = 230.0
@export var jump_velocity: float = -550.0
@export var jump_cut_multiplier: float = 0.4
@export var terminal_velocity: float = 500.0
@export var wall_jump_velocity: Vector2 = Vector2(200.0, -320.0)
@export var wall_jump_away_window: int = 8
@export var morph_double_tap_window: float = 0.3

@onready var player_sprite: AnimatedSprite2D = $PlayerSprite
@onready var morph_ball_sprite: AnimatedSprite2D = $MorphBallSprite
@onready var standing_shape: CollisionShape2D = $StandingShape
@onready var crouching_shape: CollisionShape2D = $CrouchingShape
@onready var morph_ball_shape: CollisionShape2D = $MorphBallShape
@onready var state_machine: PlayerStateMachine = $StateMachine

var facing_direction: float = 1.0
var last_down_press_time: float = -1.0
var last_wall_normal: Vector2 = Vector2.ZERO


func _ready() -> void:
	state_machine.init(self)


func _unhandled_input(event: InputEvent) -> void:
	state_machine.handle_input(event)


func _physics_process(delta: float) -> void:
	state_machine.update(delta)
	var _on_floor := move_and_slide()


func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, terminal_velocity)


func get_horizontal_input() -> float:
	return Input.get_axis("move_left", "move_right")


func is_dashing() -> bool:
	return Input.is_action_pressed("dash")


func update_facing(direction: float) -> void:
	if direction != 0.0:
		facing_direction = signf(direction)
		player_sprite.flip_h = facing_direction < 0.0
		morph_ball_sprite.flip_h = facing_direction < 0.0


func set_collision_shape(shape_name: String) -> void:
	standing_shape.disabled = true
	crouching_shape.disabled = true
	morph_ball_shape.disabled = true
	match shape_name:
		"standing":
			standing_shape.disabled = false
		"crouching":
			crouching_shape.disabled = false
		"morph_ball":
			morph_ball_shape.disabled = false


func set_sprite_mode(is_morph_ball: bool) -> void:
	player_sprite.visible = not is_morph_ball
	morph_ball_sprite.visible = is_morph_ball
	if is_morph_ball:
		morph_ball_sprite.play("roll")
	else:
		player_sprite.stop()


func can_stand_up() -> bool:
	if not crouching_shape.disabled:
		crouching_shape.disabled = true
		standing_shape.disabled = false
		var blocked := test_move(global_transform, Vector2.ZERO)
		standing_shape.disabled = true
		crouching_shape.disabled = false
		return not blocked
	if not morph_ball_shape.disabled:
		morph_ball_shape.disabled = true
		standing_shape.disabled = false
		var blocked := test_move(global_transform, Vector2.ZERO)
		standing_shape.disabled = true
		morph_ball_shape.disabled = false
		return not blocked
	return true


func register_down_press() -> void:
	last_down_press_time = Time.get_ticks_msec() / 1000.0


func is_double_tap_down() -> bool:
	var now := Time.get_ticks_msec() / 1000.0
	return (now - last_down_press_time) <= morph_double_tap_window

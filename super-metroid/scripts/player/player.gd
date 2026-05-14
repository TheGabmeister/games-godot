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

@export_group("Combat")
@export var knockback_velocity: Vector2 = Vector2(150.0, -200.0)
@export var invincibility_duration: float = 1.5
@export var max_energy: int = 99
@export var max_missiles: int = 0

signal energy_changed(current: int, maximum: int)
signal ammo_changed(weapon: StringName, current: int, maximum: int)
signal weapon_switched(weapon: StringName)
signal player_damaged(amount: int)

@onready var player_sprite: AnimatedSprite2D = $PlayerSprite
@onready var morph_ball_sprite: AnimatedSprite2D = $MorphBallSprite
@onready var standing_shape: CollisionShape2D = $StandingShape
@onready var crouching_shape: CollisionShape2D = $CrouchingShape
@onready var morph_ball_shape: CollisionShape2D = $MorphBallShape
@onready var state_machine: PlayerStateMachine = $StateMachine
@onready var damage_flasher: DamageFlasher = $DamageFlasher
@onready var weapon_system := $WeaponSystem

var facing_direction: float = 1.0
var last_down_press_time: float = -1.0
var last_wall_normal: Vector2 = Vector2.ZERO

var energy: int = 99
var missiles: int = 0
var selected_weapon: StringName = PlayerConsts.WEAPON_BEAM
var unlocked_weapons: Array[StringName] = []
var aim_direction: Vector2 = Vector2.RIGHT
var invincible: bool = false
var _invincibility_timer: float = 0.0


func _ready() -> void:
	state_machine.init(self)
	weapon_system.init(self)
	energy_changed.emit(energy, max_energy)
	weapon_switched.emit(selected_weapon)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("select_weapon"):
		cycle_weapon()
		return
	if event.is_action_pressed("cancel_weapon"):
		cancel_weapon()
		return
	state_machine.handle_input(event)


func _physics_process(delta: float) -> void:
	update_aim_direction()
	if invincible:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0.0:
			invincible = false
			damage_flasher.stop()
	state_machine.update(delta)
	weapon_system.process_fire(delta)
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
		PlayerConsts.SHAPE_STANDING:
			standing_shape.disabled = false
		PlayerConsts.SHAPE_CROUCHING:
			crouching_shape.disabled = false
		PlayerConsts.SHAPE_MORPH_BALL:
			morph_ball_shape.disabled = false


func set_sprite_mode(is_morph_ball: bool) -> void:
	player_sprite.visible = not is_morph_ball
	morph_ball_sprite.visible = is_morph_ball
	if is_morph_ball:
		morph_ball_sprite.play(PlayerConsts.ANIM_ROLL)
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


func update_aim_direction() -> void:
	var h := get_horizontal_input()
	var up_held := Input.is_action_pressed("move_up")
	var down_held := Input.is_action_pressed("move_down")
	var aim_up_held := Input.is_action_pressed("aim_up")
	var aim_down_held := Input.is_action_pressed("aim_down")

	if up_held and h == 0.0:
		aim_direction = Vector2.UP
	elif aim_up_held:
		aim_direction = Vector2(facing_direction, -1.0).normalized()
	elif aim_down_held:
		aim_direction = Vector2(facing_direction, 1.0).normalized()
	elif down_held and not is_on_floor() and h == 0.0:
		aim_direction = Vector2.DOWN
	else:
		aim_direction = Vector2(facing_direction, 0.0)


func take_damage(amount: int, source_position: Vector2 = Vector2.ZERO) -> void:
	if invincible:
		return
	energy = maxi(energy - amount, 0)
	energy_changed.emit(energy, max_energy)
	player_damaged.emit(amount)
	invincible = true
	_invincibility_timer = invincibility_duration
	damage_flasher.start(self)
	if source_position != Vector2.ZERO:
		var dir := signf(global_position.x - source_position.x)
		if dir != 0.0:
			facing_direction = -dir
	state_machine.transition_to(PlayerConsts.STATE_HURT)
	if energy <= 0:
		_die()


func _die() -> void:
	energy = max_energy
	energy_changed.emit(energy, max_energy)


func set_energy(value: int) -> void:
	energy = clampi(value, 0, max_energy)
	energy_changed.emit(energy, max_energy)


func set_missiles(value: int) -> void:
	missiles = clampi(value, 0, max_missiles)
	ammo_changed.emit(PlayerConsts.WEAPON_MISSILE, missiles, max_missiles)


func cycle_weapon() -> void:
	if unlocked_weapons.is_empty():
		return
	var idx := unlocked_weapons.find(selected_weapon)
	if idx == -1 or selected_weapon == PlayerConsts.WEAPON_BEAM:
		selected_weapon = unlocked_weapons[0]
	else:
		idx = (idx + 1) % unlocked_weapons.size()
		selected_weapon = unlocked_weapons[idx]
	weapon_switched.emit(selected_weapon)


func cancel_weapon() -> void:
	selected_weapon = PlayerConsts.WEAPON_BEAM
	weapon_switched.emit(selected_weapon)

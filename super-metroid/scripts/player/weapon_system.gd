extends Node

const MAX_BEAMS: int = 3
const CHARGE_TIME: float = 2.0
const BEAM_DAMAGE: int = 20
const CHARGE_DAMAGE: int = 60
const MISSILE_DAMAGE: int = 100
const MAX_BOMBS: int = 3

@export var power_beam_scene: PackedScene
@export var charge_beam_scene: PackedScene
@export var missile_scene: PackedScene
@export var bomb_scene: PackedScene

var active_beams: int = 0
var active_bombs: int = 0
var charge_timer: float = 0.0
var is_charging: bool = false

var _player: Player


func _ready() -> void:
	_player = get_parent() as Player


func _physics_process(delta: float) -> void:
	_process_fire(delta)


func _process_fire(delta: float) -> void:
	var fire_held := Input.is_action_pressed("fire")
	var fire_just_pressed := Input.is_action_just_pressed("fire")
	var fire_just_released := Input.is_action_just_released("fire")

	var current_state_name := _player.state_machine.current_state.name.to_lower()
	var in_morph_ball := current_state_name == PlayerConsts.STATE_MORPH_BALL
	var in_spin_jump := current_state_name == PlayerConsts.STATE_SPIN_JUMP
	var in_hurt := current_state_name == PlayerConsts.STATE_HURT

	if in_hurt:
		charge_timer = 0.0
		is_charging = false
		return

	if in_morph_ball:
		_handle_morph_ball_fire(fire_just_pressed)
		charge_timer = 0.0
		is_charging = false
		return

	var weapon := _player.selected_weapon
	if weapon == PlayerConsts.WEAPON_MISSILE:
		if fire_just_pressed:
			_fire_missile()
		charge_timer = 0.0
		is_charging = false
		return

	if in_spin_jump:
		charge_timer = 0.0
		is_charging = false
		return

	if fire_held:
		charge_timer += delta
		if charge_timer >= CHARGE_TIME:
			is_charging = true
	elif fire_just_released:
		if is_charging:
			_fire_charge_beam()
		else:
			_fire_beam()
		charge_timer = 0.0
		is_charging = false
	else:
		charge_timer = 0.0
		is_charging = false


func _fire_beam() -> void:
	if active_beams >= MAX_BEAMS:
		return
	if not power_beam_scene:
		return
	var proj: Projectile = power_beam_scene.instantiate()
	proj.direction = _player.aim_direction
	proj.damage = BEAM_DAMAGE
	proj.global_position = _get_muzzle_position()
	proj.rotation = _player.aim_direction.angle()
	_player.get_parent().add_child(proj)
	active_beams += 1
	var _err := proj.tree_exited.connect(_on_beam_exited)
	SfxManager.play(preload("res://combat/audio/beam_fire.ogg"))


func _fire_charge_beam() -> void:
	if not charge_beam_scene:
		return
	var proj: Projectile = charge_beam_scene.instantiate()
	proj.direction = _player.aim_direction
	proj.damage = CHARGE_DAMAGE
	proj.global_position = _get_muzzle_position()
	proj.rotation = _player.aim_direction.angle()
	_player.get_parent().add_child(proj)
	SfxManager.play(preload("res://combat/audio/charge_release.ogg"))


func _fire_missile() -> void:
	if _player.missiles <= 0:
		return
	if not missile_scene:
		return
	_player.set_missiles(_player.missiles - 1)
	var proj: Projectile = missile_scene.instantiate()
	proj.direction = _player.aim_direction
	proj.damage = MISSILE_DAMAGE
	proj.global_position = _get_muzzle_position()
	proj.rotation = _player.aim_direction.angle()
	_player.get_parent().add_child(proj)
	SfxManager.play(preload("res://combat/audio/missile_launch.ogg"))


func _handle_morph_ball_fire(just_pressed: bool) -> void:
	if not just_pressed:
		return
	if active_bombs >= MAX_BOMBS:
		return
	if not bomb_scene:
		return
	var b: Bomb = bomb_scene.instantiate()
	b.global_position = _player.global_position
	_player.get_parent().add_child(b)
	active_bombs += 1
	var _err := b.tree_exited.connect(_on_bomb_exited)
	SfxManager.play(preload("res://combat/audio/bomb_place.ogg"))


func _get_muzzle_position() -> Vector2:
	var offset := _player.aim_direction * 20.0
	return _player.global_position + Vector2(0.0, -24.0) + offset


func _on_beam_exited() -> void:
	active_beams = maxi(active_beams - 1, 0)


func _on_bomb_exited() -> void:
	active_bombs = maxi(active_bombs - 1, 0)

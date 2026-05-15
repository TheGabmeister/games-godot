extends Node

const MAX_BEAMS: int = 3
const CHARGE_TIME: float = 2.0
const BEAM_DAMAGE: int = 20
const CHARGE_DAMAGE: int = 60
const MISSILE_DAMAGE: int = 100
const MAX_BOMBS: int = 3

@export_group("Scenes")
@export var power_beam_scene: PackedScene
@export var charge_beam_scene: PackedScene
@export var missile_scene: PackedScene
@export var bomb_scene: PackedScene

@export_group("Audio")
@export var beam_fire_sfx: AudioStream
@export var charge_release_sfx: AudioStream
@export var missile_launch_sfx: AudioStream
@export var bomb_place_sfx: AudioStream

var active_beams: int = 0
var active_bombs: int = 0
var charge_timer: float = 0.0
var is_charging: bool = false

var _player: Player


func _ready() -> void:
	_player = get_parent() as Player


func _physics_process(delta: float) -> void:
	if GameManager.transitioning:
		_reset_charge()
		return
	_process_fire(delta)


func _process_fire(delta: float) -> void:
	var fire_held := Input.is_action_pressed("fire")
	var fire_just_pressed := Input.is_action_just_pressed("fire")
	var fire_just_released := Input.is_action_just_released("fire")

	var current_state_name := _player.state_machine.current_state.name.to_lower()
	var in_morph_ball := current_state_name == PlayerConsts.STATE_MORPH_BALL
	var in_spin_jump := current_state_name == PlayerConsts.STATE_SPIN_JUMP
	var in_hurt := current_state_name == PlayerConsts.STATE_HURT

	if in_hurt or in_spin_jump:
		_reset_charge()
		return

	if in_morph_ball:
		_handle_morph_ball_fire(fire_just_pressed)
		_reset_charge()
		return

	if _player.selected_weapon == PlayerConsts.WEAPON_MISSILE:
		if fire_just_pressed:
			_fire_missile()
		_reset_charge()
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
		_reset_charge()
	else:
		_reset_charge()


func _reset_charge() -> void:
	charge_timer = 0.0
	is_charging = false


func _spawn_projectile(scene: PackedScene, damage: int, sfx: AudioStream) -> Projectile:
	var proj: Projectile = scene.instantiate()
	proj.direction = _player.aim_direction
	proj.damage = damage
	proj.global_position = _get_muzzle_position()
	proj.rotation = _player.aim_direction.angle()
	GameManager.current_room.add_child(proj)
	SfxManager.play(sfx)
	return proj


func _fire_beam() -> void:
	if active_beams >= MAX_BEAMS or not power_beam_scene:
		return
	var proj := _spawn_projectile(power_beam_scene, BEAM_DAMAGE, beam_fire_sfx)
	active_beams += 1
	var _err := proj.tree_exited.connect(_on_beam_exited)


func _fire_charge_beam() -> void:
	if not charge_beam_scene:
		return
	var _proj := _spawn_projectile(charge_beam_scene, CHARGE_DAMAGE, charge_release_sfx)


func _fire_missile() -> void:
	if _player.missiles <= 0 or not missile_scene:
		return
	_player.set_missiles(_player.missiles - 1)
	var _proj := _spawn_projectile(missile_scene, MISSILE_DAMAGE, missile_launch_sfx)


func _handle_morph_ball_fire(just_pressed: bool) -> void:
	if not just_pressed:
		return
	if active_bombs >= MAX_BOMBS:
		return
	if not bomb_scene:
		return
	var b: Bomb = bomb_scene.instantiate()
	b.global_position = _player.global_position
	GameManager.current_room.add_child(b)
	active_bombs += 1
	var _err := b.tree_exited.connect(_on_bomb_exited)
	SfxManager.play(bomb_place_sfx)


func _get_muzzle_position() -> Vector2:
	var offset := _player.aim_direction * 20.0
	return _player.global_position + Vector2(0.0, -24.0) + offset


func _on_beam_exited() -> void:
	active_beams = maxi(active_beams - 1, 0)


func _on_bomb_exited() -> void:
	active_bombs = maxi(active_bombs - 1, 0)

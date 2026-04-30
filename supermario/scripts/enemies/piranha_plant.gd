extends Node2D

const SpriteHelper := preload("res://scripts/visuals/sprite_region_helper.gd")
const SHEET := preload("res://sprites/piranha_plant_sheet.png")
const EMERGE_HEIGHT: float = 24.0
const EMERGE_DURATION: float = 0.8
const WAIT_TOP_DURATION: float = 1.5
const WAIT_BOTTOM_DURATION: float = 1.5

enum State { WAITING_BOTTOM, EMERGING, WAITING_TOP, RETRACTING }

var _state: State = State.WAITING_BOTTOM
var _timer: float = 0.0
var _offset_y: float = 0.0  # 0 = hidden, -EMERGE_HEIGHT = fully emerged
var _is_active: bool = false
var _is_dead: bool = false
var _player_in_zone: bool = false

@onready var _hitbox: Area2D = $Hitbox
@onready var _hitbox_shape: CollisionShape2D = $Hitbox/HitboxShape
@onready var _proximity_zone: Area2D = $ProximityZone

var _sprite: Sprite2D


func _ready() -> void:
	set_physics_process(false)
	visible = false
	add_to_group("enemies")
	_hitbox_shape.position.y = 0.0
	_proximity_zone.body_entered.connect(_on_proximity_body_entered)
	_proximity_zone.body_exited.connect(_on_proximity_body_exited)
	_sprite = SpriteHelper.ensure_sprite(self, &"Sprite", SHEET)
	SpriteHelper.set_cell(_sprite, 0, 4, Vector2(-16, -30))


func activate() -> void:
	if _is_active:
		return
	_is_active = true
	set_physics_process(true)
	visible = true


func is_active() -> bool:
	return _is_active


func is_dead() -> bool:
	return _is_dead


func is_dangerous() -> bool:
	return _is_active and not _is_dead


func is_stompable() -> bool:
	return false


func stomp_kill() -> bool:
	return false


func non_stomp_kill() -> void:
	_die()


func shell_kill() -> void:
	_die()


func _die() -> void:
	if _is_dead:
		return
	_is_dead = true
	GameManager.add_score(200, global_position)
	EventBus.enemy_killed.emit(global_position, &"piranha_plant")
	call_deferred("queue_free")


func die() -> void:
	_die()


func _physics_process(delta: float) -> void:
	if _is_dead:
		return

	_timer += delta

	match _state:
		State.WAITING_BOTTOM:
			if _timer >= WAIT_BOTTOM_DURATION:
				if not _player_in_zone:
					_state = State.EMERGING
					_timer = 0.0
				else:
					_timer = 0.0  # keep waiting

		State.EMERGING:
			var t: float = minf(_timer / EMERGE_DURATION, 1.0)
			_offset_y = -EMERGE_HEIGHT * t
			if t >= 1.0:
				_state = State.WAITING_TOP
				_timer = 0.0

		State.WAITING_TOP:
			if _timer >= WAIT_TOP_DURATION:
				_state = State.RETRACTING
				_timer = 0.0

		State.RETRACTING:
			var t: float = minf(_timer / EMERGE_DURATION, 1.0)
			_offset_y = -EMERGE_HEIGHT * (1.0 - t)
			if t >= 1.0:
				_offset_y = 0.0
				_state = State.WAITING_BOTTOM
				_timer = 0.0

	# Update hitbox — disable when fully retracted
	var is_visible: bool = _state != State.WAITING_BOTTOM
	_hitbox_shape.set_deferred("disabled", not is_visible)
	_hitbox_shape.position.y = _offset_y - 8.0

	_update_sprite()


func _on_proximity_body_entered(_body: Node2D) -> void:
	_player_in_zone = true


func _on_proximity_body_exited(_body: Node2D) -> void:
	_player_in_zone = false


func _update_sprite() -> void:
	if _sprite == null:
		return
	_sprite.visible = _is_active and not _is_dead and _state != State.WAITING_BOTTOM
	var frame := clampi(roundi(absf(_offset_y) / 8.0), 0, 3)
	SpriteHelper.set_cell(_sprite, frame, 4, Vector2(-16, -30 + _offset_y))

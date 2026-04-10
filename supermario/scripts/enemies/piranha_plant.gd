extends Node2D

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


func _ready() -> void:
	set_physics_process(false)
	visible = false
	add_to_group("enemies")
	_hitbox_shape.position.y = 0.0
	_proximity_zone.body_entered.connect(_on_proximity_body_entered)
	_proximity_zone.body_exited.connect(_on_proximity_body_exited)


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

	queue_redraw()


func _on_proximity_body_entered(_body: Node2D) -> void:
	_player_in_zone = true


func _on_proximity_body_exited(_body: Node2D) -> void:
	_player_in_zone = false


func _draw() -> void:
	if _is_dead or not _is_active:
		return

	var base_y: float = _offset_y

	# Stem
	draw_rect(Rect2(-3, base_y, 6, -base_y), Palette.PIRANHA_GREEN)

	# Head (only draw if visible)
	if base_y < -2.0:
		# Head body
		draw_rect(Rect2(-7, base_y - 10, 14, 10), Palette.PIRANHA_GREEN)
		# Lips / spots
		draw_rect(Rect2(-8, base_y - 10, 16, 3), Palette.PIRANHA_RED)
		draw_rect(Rect2(-8, base_y - 1, 16, 2), Palette.PIRANHA_RED)
		# White teeth
		draw_rect(Rect2(-4, base_y - 7, 2, 3), Color.WHITE)
		draw_rect(Rect2(2, base_y - 7, 2, 3), Color.WHITE)

extends BaseEnemyState

const MOVE_TIME_MIN := 1.5
const MOVE_TIME_MAX := 3.0
const PAUSE_TIME := 0.8

var _direction: Vector2 = Vector2.DOWN
var _move_timer: float = 0.0
var _pause_timer: float = 0.0
var _paused: bool = false


func enter(msg: Dictionary = {}) -> void:
	super.enter(msg)
	_pick_direction()


func physics_update(delta: float) -> void:
	if not actor:
		return

	if actor.knockback_component.is_active():
		return

	if _paused:
		_pause_timer -= delta
		if _pause_timer <= 0.0:
			_paused = false
			_pick_direction()
		return

	_move_timer -= delta
	if _move_timer <= 0.0:
		actor.velocity = Vector2.ZERO
		_paused = true
		_pause_timer = PAUSE_TIME
		return

	actor.velocity = _direction * actor.wander_speed
	actor.update_facing(_direction)
	actor.move_and_slide()

	if actor.get_slide_collision_count() > 0:
		_pick_direction()


func _pick_direction() -> void:
	var dirs: Array[Vector2] = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	_direction = dirs[randi() % dirs.size()]
	_move_timer = randf_range(MOVE_TIME_MIN, MOVE_TIME_MAX)

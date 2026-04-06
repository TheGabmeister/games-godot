extends BaseEnemyState

var _current_point: int = 0
var _waiting: bool = false
var _wait_timer: float = 0.0


func enter(msg: Dictionary = {}) -> void:
	super.enter(msg)
	_waiting = false
	_wait_timer = 0.0


func physics_update(delta: float) -> void:
	if not actor:
		return

	# Check for player detection -> chase
	if actor.player_detected:
		state_machine.transition_to(&"Chase")
		return

	if actor.knockback_component.is_active():
		return

	var points: PackedVector2Array = actor.global_patrol_points
	if points.is_empty():
		return

	if _waiting:
		_wait_timer -= delta
		if _wait_timer <= 0.0:
			_waiting = false
			_current_point = (_current_point + 1) % points.size()
		return

	var target: Vector2 = points[_current_point]
	var to_target: Vector2 = target - actor.global_position
	var dist: float = to_target.length()

	if dist < 2.0:
		# Arrived at waypoint
		actor.velocity = Vector2.ZERO
		_waiting = true
		_wait_timer = actor.patrol_wait_time
		return

	var dir: Vector2 = to_target.normalized()
	actor.velocity = dir * actor.patrol_speed
	actor.update_facing(dir)
	actor.move_and_slide()

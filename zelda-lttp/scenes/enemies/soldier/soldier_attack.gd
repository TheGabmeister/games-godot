extends BaseEnemyState

const LUNGE_SPEED := 140.0
const LUNGE_DURATION := 0.2
const RECOVERY_DURATION := 0.3

var _timer: float = 0.0
var _lunge_dir: Vector2 = Vector2.ZERO
var _recovering: bool = false


func enter(msg: Dictionary = {}) -> void:
	super.enter(msg)
	_timer = 0.0
	_recovering = false
	if actor and actor.player_ref:
		_lunge_dir = (actor.player_ref.global_position - actor.global_position).normalized()
		actor.update_facing(_lunge_dir)
	else:
		_lunge_dir = actor.facing_direction if actor else Vector2.DOWN


func physics_update(delta: float) -> void:
	if not actor:
		return

	_timer += delta

	if not _recovering:
		if _timer < LUNGE_DURATION:
			actor.velocity = _lunge_dir * LUNGE_SPEED
			actor.move_and_slide()
		else:
			actor.velocity = Vector2.ZERO
			_recovering = true
			_timer = 0.0
	else:
		if _timer >= RECOVERY_DURATION:
			state_machine.transition_to(&"Chase")

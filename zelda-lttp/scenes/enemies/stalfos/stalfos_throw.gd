extends BaseEnemyState

const THROW_PAUSE := 0.5

var _timer: float = 0.0
var _thrown: bool = false


func enter(msg: Dictionary = {}) -> void:
	super.enter(msg)
	_timer = 0.0
	_thrown = false
	if actor:
		actor.velocity = Vector2.ZERO


func physics_update(delta: float) -> void:
	if not actor:
		return

	_timer += delta

	if not _thrown and _timer >= 0.15:
		actor.spawn_bone()
		AudioManager.play_sfx(&"enemy_shoot")
		_thrown = true

	if _timer >= THROW_PAUSE:
		state_machine.transition_to(&"Wander")

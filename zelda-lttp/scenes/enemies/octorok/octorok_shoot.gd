extends BaseEnemyState

const SHOOT_PAUSE := 0.4

var _timer: float = 0.0
var _fired: bool = false


func enter(msg: Dictionary = {}) -> void:
	super.enter(msg)
	_timer = 0.0
	_fired = false
	if actor:
		actor.velocity = Vector2.ZERO


func physics_update(delta: float) -> void:
	if not actor:
		return

	_timer += delta

	if not _fired and _timer >= 0.1:
		actor.spawn_projectile()
		AudioManager.play_sfx(&"enemy_shoot")
		_fired = true

	if _timer >= SHOOT_PAUSE:
		state_machine.transition_to(&"Wander")

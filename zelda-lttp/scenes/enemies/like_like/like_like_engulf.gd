extends BaseEnemyState
## Captures the player. Player must mash to escape; timeout drops shield tier.

var _timer: float = 0.0


func enter(msg: Dictionary = {}) -> void:
	super.enter(msg)
	_timer = 0.0
	actor.velocity = Vector2.ZERO
	actor.engulf_player()
	# Redraw body to show engulf visual
	var body: Node2D = actor.get_node_or_null("EnemyBody")
	if body:
		body.queue_redraw()


func update(delta: float) -> void:
	_timer += delta
	# The TrappedState on the player handles the escape/timeout logic.
	# If the player escapes or times out, release_player() is called,
	# which transitions this state back to Idle.
	# Safety fallback: if we've been here too long without release, go idle
	if _timer > 5.0:
		actor.release_player()


func exit() -> void:
	actor._is_engulfing = false
	var body: Node2D = actor.get_node_or_null("EnemyBody")
	if body:
		body.queue_redraw()

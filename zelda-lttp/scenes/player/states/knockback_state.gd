extends BasePlayerState

var _knockback_timer: float = 0.0
const KNOCKBACK_DURATION := 0.2
const KNOCKBACK_SPEED := 200.0
var _direction: Vector2 = Vector2.ZERO


func enter(msg: Dictionary = {}) -> void:
	super.enter(msg)
	_knockback_timer = 0.0
	_direction = msg.get("direction", -player.facing_direction).normalized()
	player.velocity = _direction * KNOCKBACK_SPEED


func physics_update(delta: float) -> void:
	_knockback_timer += delta

	# Decelerate
	var t := _knockback_timer / KNOCKBACK_DURATION
	player.velocity = _direction * KNOCKBACK_SPEED * (1.0 - t)
	player.move_and_slide()

	if _knockback_timer >= KNOCKBACK_DURATION:
		state_machine.transition_to(&"Idle")

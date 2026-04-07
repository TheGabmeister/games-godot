extends BaseEnemyState
## Stationary, waits for player detection.


func physics_update(_delta: float) -> void:
	if actor.player_detected:
		state_machine.transition_to(&"Pursue")

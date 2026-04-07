extends BaseEnemyState
## Slow movement toward the player.


func physics_update(delta: float) -> void:
	if not actor.player_detected or not actor.player_ref:
		state_machine.transition_to(&"Idle")
		return

	var to_player: Vector2 = actor.player_ref.global_position - actor.global_position
	var dist := to_player.length()

	# Lost interest
	if dist > actor.lose_interest_radius:
		state_machine.transition_to(&"Idle")
		return

	# Close enough to engulf
	if dist < actor.engulf_range:
		state_machine.transition_to(&"Engulf")
		return

	# Move toward player
	var dir := to_player.normalized()
	actor.velocity = dir * actor.pursue_speed
	actor.move_and_slide()
	actor.update_facing(dir)

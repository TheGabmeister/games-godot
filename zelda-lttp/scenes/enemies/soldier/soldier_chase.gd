extends BaseEnemyState

const ATTACK_RANGE := 20.0


func physics_update(_delta: float) -> void:
	if not actor or not actor.player_ref:
		state_machine.transition_to(&"Patrol")
		return

	if actor.knockback_component.is_active():
		return

	var to_player: Vector2 = actor.player_ref.global_position - actor.global_position
	var dist: float = to_player.length()

	# Lost interest — player too far
	if dist > actor.lose_interest_radius:
		actor.player_detected = false
		state_machine.transition_to(&"Patrol")
		return

	# Close enough to attack
	if dist < ATTACK_RANGE:
		state_machine.transition_to(&"Attack")
		return

	var dir: Vector2 = to_player.normalized()
	actor.velocity = dir * actor.chase_speed
	actor.update_facing(dir)
	actor.move_and_slide()

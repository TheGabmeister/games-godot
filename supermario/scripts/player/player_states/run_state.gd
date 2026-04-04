extends "res://scripts/player/player_states/player_state.gd"


func process_physics(delta: float) -> void:
	player.apply_gravity(delta)

	if not player.is_on_floor():
		player.start_coyote_timer()
		state_machine.transition_to(&"FallState")
		return

	if Input.is_action_just_pressed(&"jump"):
		state_machine.transition_to(&"JumpState")
		return

	var direction := Input.get_axis(&"move_left", &"move_right")
	if direction == 0.0:
		player.apply_deceleration(delta)
		if absf(player.velocity.x) < 10.0:
			state_machine.transition_to(&"IdleState")
			return
	else:
		player.apply_movement(direction, delta)
		player.update_facing(direction)

	player.move_and_slide()

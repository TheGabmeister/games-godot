extends "res://scripts/player/player_states/player_state.gd"


func process_physics(delta: float) -> void:
	player.apply_gravity(delta)

	if player.is_on_floor():
		# Check jump buffer
		if player.jump_buffered:
			state_machine.transition_to(StateIds.JUMP)
			return
		var direction := Input.get_axis(&"move_left", &"move_right")
		if direction != 0.0:
			state_machine.transition_to(StateIds.RUN)
		else:
			state_machine.transition_to(StateIds.IDLE)
		return

	# Coyote time jump
	if Input.is_action_just_pressed(&"jump"):
		if player.coyote_active:
			state_machine.transition_to(StateIds.JUMP)
			return
		else:
			player.buffer_jump()

	# Air control
	var direction := Input.get_axis(&"move_left", &"move_right")
	if direction != 0.0:
		player.apply_air_movement(direction, delta)
		player.update_facing(direction)

	player.move_and_slide()

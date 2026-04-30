extends "res://scripts/player/player_states/player_state.gd"


func enter() -> void:
	var speed_ratio: float = absf(player.velocity.x) / player.movement.run_speed
	var jump_boost: float = lerpf(1.0, player.movement.high_speed_jump_boost, speed_ratio)
	player.velocity.y = player.movement.jump_velocity * jump_boost
	if player.has_method("play_jump_sound"):
		player.play_jump_sound()


func process_physics(delta: float) -> void:
	# Variable-height jump: cut velocity on release
	if not Input.is_action_pressed(&"jump") and player.velocity.y < 0.0:
		player.velocity.y *= player.movement.jump_release_mult
		state_machine.transition_to(StateIds.FALL)
		return

	player.apply_gravity(delta)

	if player.velocity.y >= 0.0:
		state_machine.transition_to(StateIds.FALL)
		return

	# Air control
	var direction := Input.get_axis(&"move_left", &"move_right")
	if direction != 0.0:
		player.apply_air_movement(direction, delta)
		player.update_facing(direction)

	player.move_and_slide()
	player.check_ceiling_bumps()

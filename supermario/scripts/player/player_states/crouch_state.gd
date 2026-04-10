extends "res://scripts/player/player_states/player_state.gd"


func enter() -> void:
	player.velocity.x = 0.0
	player.set_crouching(true)


func exit() -> void:
	player.set_crouching(false)


func process_physics(delta: float) -> void:
	player.apply_gravity(delta)

	if not player.is_on_floor():
		state_machine.transition_to(StateIds.FALL)
		return

	if not Input.is_action_pressed(&"crouch"):
		if player.has_ceiling_clearance():
			state_machine.transition_to(StateIds.IDLE)
		return

	if Input.is_action_just_pressed(&"jump"):
		if player.has_ceiling_clearance():
			state_machine.transition_to(StateIds.JUMP)
		return

	player.move_and_slide()

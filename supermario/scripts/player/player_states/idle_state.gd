extends "res://scripts/player/player_states/player_state.gd"


func enter() -> void:
	player.velocity.x = 0.0


func process_physics(delta: float) -> void:
	player.apply_gravity(delta)

	if not player.is_on_floor():
		state_machine.transition_to(&"FallState")
		return

	if Input.is_action_just_pressed(&"jump"):
		state_machine.transition_to(&"JumpState")
		return

	var direction := Input.get_axis(&"move_left", &"move_right")
	if direction != 0.0:
		state_machine.transition_to(&"RunState")
		return

	if Input.is_action_pressed(&"crouch") and player.can_crouch():
		state_machine.transition_to(&"CrouchState")
		return

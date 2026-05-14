extends PlayerState


func enter() -> void:
	player.velocity.x = 0.0
	player.set_collision_shape("standing")
	player.set_sprite_mode(false)
	player.samus_sprite.play("idle")


func update(delta: float) -> void:
	player.apply_gravity(delta)

	if not player.is_on_floor():
		state_machine.transition_to("fall")
		return

	var direction := player.get_horizontal_input()
	if direction != 0.0:
		if player.is_dashing():
			state_machine.transition_to("run")
		else:
			state_machine.transition_to("walk")
		return

	if Input.is_action_just_pressed("jump"):
		state_machine.transition_to("jump")
		return

	if Input.is_action_just_pressed("move_down"):
		player.register_down_press()
		state_machine.transition_to("crouch")
		return

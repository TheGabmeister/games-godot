extends PlayerState


func enter() -> void:
	player.velocity.x = 0.0
	player.set_collision_shape("crouching")
	player.set_sprite_mode(false)
	player.player_sprite.play("crouch")


func update(delta: float) -> void:
	player.apply_gravity(delta)

	if not player.is_on_floor():
		state_machine.transition_to("fall")
		return

	if Input.is_action_just_pressed("move_up"):
		if player.can_stand_up():
			state_machine.transition_to("idle")
		return

	if Input.is_action_just_pressed("move_down"):
		if player.is_double_tap_down():
			state_machine.transition_to("morphball")
			return
		player.register_down_press()

	if Input.is_action_just_pressed("jump"):
		if player.can_stand_up():
			state_machine.transition_to("jump")
		return

extends PlayerState


func enter() -> void:
	player.velocity.x = 0.0
	player.set_collision_shape(PlayerConsts.SHAPE_CROUCHING)
	player.set_sprite_mode(false)
	player.player_sprite.play(PlayerConsts.ANIM_CROUCH)


func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_up"):
		if player.can_stand_up():
			state_machine.transition_to(PlayerConsts.STATE_IDLE)
		return

	if event.is_action_pressed("move_down"):
		if player.is_double_tap_down():
			state_machine.transition_to(PlayerConsts.STATE_MORPH_BALL)
			return
		player.register_down_press()
		return

	if event.is_action_pressed("jump"):
		if player.can_stand_up():
			state_machine.transition_to(PlayerConsts.STATE_JUMP)
		return


func update(delta: float) -> void:
	player.apply_gravity(delta)

	if not player.is_on_floor():
		state_machine.transition_to(PlayerConsts.STATE_FALL)
		return

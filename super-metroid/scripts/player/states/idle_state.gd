extends PlayerState


func enter() -> void:
	player.velocity.x = 0.0
	player.set_collision_shape(PlayerConsts.SHAPE_STANDING)
	player.set_sprite_mode(false)
	player.player_sprite.play(PlayerConsts.ANIM_IDLE)


func update(delta: float) -> void:
	player.apply_gravity(delta)

	if not player.is_on_floor():
		state_machine.transition_to(PlayerConsts.STATE_FALL)
		return

	var direction := player.get_horizontal_input()
	if direction != 0.0:
		if player.is_dashing():
			state_machine.transition_to(PlayerConsts.STATE_RUN)
		else:
			state_machine.transition_to(PlayerConsts.STATE_WALK)
		return

	if Input.is_action_just_pressed("jump"):
		state_machine.transition_to(PlayerConsts.STATE_JUMP)
		return

	if Input.is_action_just_pressed("move_down"):
		player.register_down_press()
		state_machine.transition_to(PlayerConsts.STATE_CROUCH)
		return

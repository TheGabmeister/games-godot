extends PlayerState


func enter() -> void:
	player.set_collision_shape(PlayerConsts.SHAPE_STANDING)
	player.set_sprite_mode(false)
	player.player_sprite.play(PlayerConsts.ANIM_WALK)


func update(delta: float) -> void:
	player.apply_gravity(delta)

	if not player.is_on_floor():
		state_machine.transition_to(PlayerConsts.STATE_FALL)
		return

	var direction := player.get_horizontal_input()

	if direction == 0.0:
		state_machine.transition_to(PlayerConsts.STATE_IDLE)
		return

	if player.is_dashing():
		state_machine.transition_to(PlayerConsts.STATE_RUN)
		return

	if Input.is_action_just_pressed("jump"):
		state_machine.transition_to(PlayerConsts.STATE_SPIN_JUMP)
		return

	if Input.is_action_just_pressed("move_down"):
		player.register_down_press()
		state_machine.transition_to(PlayerConsts.STATE_CROUCH)
		return

	player.update_facing(direction)
	player.velocity.x = direction * player.walk_speed

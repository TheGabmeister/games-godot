extends PlayerState


func enter() -> void:
	player.set_collision_shape(PlayerConsts.SHAPE_MORPH_BALL)
	player.set_sprite_mode(true)


func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_up"):
		if player.can_stand_up():
			state_machine.transition_to(PlayerConsts.STATE_IDLE)
		return


func update(delta: float) -> void:
	player.apply_gravity(delta)

	var direction := player.get_horizontal_input()
	if player.is_on_floor():
		if direction != 0.0:
			player.update_facing(direction)
			if player.is_dashing():
				player.velocity.x = direction * player.run_speed
			else:
				player.velocity.x = direction * player.walk_speed
		else:
			player.velocity.x = move_toward(player.velocity.x, 0.0, player.walk_speed * delta * 10.0)
	else:
		if direction != 0.0:
			player.update_facing(direction)
			player.velocity.x = direction * player.walk_speed

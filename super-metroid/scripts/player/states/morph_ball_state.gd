extends PlayerState


func enter() -> void:
	player.set_collision_shape("morph_ball")
	player.set_sprite_mode(true)


func update(delta: float) -> void:
	player.apply_gravity(delta)

	if Input.is_action_just_pressed("move_up"):
		if player.can_stand_up():
			state_machine.transition_to("idle")
			return

	if player.is_on_floor():
		var direction := player.get_horizontal_input()
		if direction != 0.0:
			player.update_facing(direction)
			if player.is_dashing():
				player.velocity.x = direction * player.run_speed
			else:
				player.velocity.x = direction * player.walk_speed
		else:
			player.velocity.x = move_toward(player.velocity.x, 0.0, player.walk_speed * delta * 10.0)
	else:
		var direction := player.get_horizontal_input()
		if direction != 0.0:
			player.update_facing(direction)
			player.velocity.x = direction * player.walk_speed

extends PlayerState

var down_press_count: int = 0


func enter() -> void:
	player.set_collision_shape(PlayerConsts.SHAPE_STANDING)
	player.set_sprite_mode(false)
	player.velocity.y = player.jump_velocity
	player.player_sprite.play(PlayerConsts.ANIM_FALL)
	down_press_count = 0


func handle_input(event: InputEvent) -> void:
	if event.is_action_released("jump") and player.velocity.y < 0.0:
		player.velocity.y *= player.jump_cut_multiplier

	if event.is_action_pressed("move_down"):
		down_press_count += 1
		if down_press_count == 1:
			player.register_down_press()
		elif down_press_count >= 2 and player.is_double_tap_down():
			state_machine.transition_to(PlayerConsts.STATE_MORPH_BALL)


func update(delta: float) -> void:
	player.apply_gravity(delta)
	var direction := player.get_horizontal_input()

	if player.is_on_floor():
		if direction != 0.0:
			state_machine.transition_to(PlayerConsts.STATE_WALK)
		else:
			state_machine.transition_to(PlayerConsts.STATE_IDLE)
		return

	if player.velocity.y > 0.0:
		state_machine.transition_to(PlayerConsts.STATE_FALL)
		return
	player.update_facing(direction)
	if player.is_dashing() and direction != 0.0:
		player.velocity.x = direction * player.run_speed
	elif direction != 0.0:
		player.velocity.x = direction * player.walk_speed
	else:
		player.velocity.x = move_toward(player.velocity.x, 0.0, player.walk_speed * delta * 5.0)

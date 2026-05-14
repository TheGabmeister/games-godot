extends PlayerState

var down_press_count: int = 0


func enter() -> void:
	player.set_collision_shape("standing")
	player.set_sprite_mode(false)
	player.samus_sprite.play("fall")
	down_press_count = 0


func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_down"):
		down_press_count += 1
		if down_press_count == 1:
			player.register_down_press()
		elif down_press_count >= 2 and player.is_double_tap_down():
			state_machine.transition_to("morphball")


func update(delta: float) -> void:
	player.apply_gravity(delta)

	if player.is_on_floor():
		var direction := player.get_horizontal_input()
		if direction != 0.0:
			if player.is_dashing():
				state_machine.transition_to("run")
			else:
				state_machine.transition_to("walk")
		else:
			state_machine.transition_to("idle")
		return

	var direction := player.get_horizontal_input()
	player.update_facing(direction)
	if player.is_dashing() and direction != 0.0:
		player.velocity.x = direction * player.run_speed
	elif direction != 0.0:
		player.velocity.x = direction * player.walk_speed
	else:
		player.velocity.x = move_toward(player.velocity.x, 0.0, player.walk_speed * delta * 5.0)

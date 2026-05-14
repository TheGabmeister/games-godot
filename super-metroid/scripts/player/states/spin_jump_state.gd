extends PlayerState

var wall_away_timer: int = 0
var down_press_count: int = 0


func enter() -> void:
	player.set_collision_shape("standing")
	player.set_sprite_mode(false)
	player.velocity.y = player.jump_velocity
	player.player_sprite.play("spin_jump")
	wall_away_timer = 0
	player.last_wall_normal = Vector2.ZERO
	down_press_count = 0


func handle_input(event: InputEvent) -> void:
	if event.is_action_released("jump") and player.velocity.y < 0.0:
		player.velocity.y *= player.jump_cut_multiplier

	if event.is_action_pressed("move_down"):
		down_press_count += 1
		if down_press_count == 1:
			player.register_down_press()
		elif down_press_count >= 2 and player.is_double_tap_down():
			state_machine.transition_to("morphball")

	if event.is_action_pressed("jump") and wall_away_timer > 0:
		state_machine.transition_to("walljump")


func update(delta: float) -> void:
	player.apply_gravity(delta)

	if player.is_on_floor():
		var direction := player.get_horizontal_input()
		if direction != 0.0:
			state_machine.transition_to("walk")
		else:
			state_machine.transition_to("idle")
		return

	# Wall jump detection
	if player.is_on_wall():
		player.last_wall_normal = player.get_wall_normal()

	if player.last_wall_normal != Vector2.ZERO:
		var away_direction := player.last_wall_normal.x
		var input_direction := player.get_horizontal_input()
		if signf(input_direction) == signf(away_direction) and input_direction != 0.0:
			wall_away_timer = player.wall_jump_away_window
		else:
			wall_away_timer = maxi(wall_away_timer - 1, 0)
	else:
		wall_away_timer = maxi(wall_away_timer - 1, 0)
		if not player.is_on_wall():
			player.last_wall_normal = Vector2.ZERO

	var direction := player.get_horizontal_input()
	player.update_facing(direction)
	if player.is_dashing() and direction != 0.0:
		player.velocity.x = direction * player.run_speed
	elif direction != 0.0:
		player.velocity.x = direction * player.walk_speed
	else:
		player.velocity.x = move_toward(player.velocity.x, 0.0, player.walk_speed * delta * 5.0)

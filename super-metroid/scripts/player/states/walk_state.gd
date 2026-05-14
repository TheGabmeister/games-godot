extends PlayerState


func enter() -> void:
	player.set_collision_shape("standing")
	player.set_sprite_mode(false)
	player.samus_sprite.play("walk")


func update(delta: float) -> void:
	player.apply_gravity(delta)

	if not player.is_on_floor():
		state_machine.transition_to("fall")
		return

	var direction := player.get_horizontal_input()

	if direction == 0.0:
		state_machine.transition_to("idle")
		return

	if player.is_dashing():
		state_machine.transition_to("run")
		return

	if Input.is_action_just_pressed("jump"):
		state_machine.transition_to("spinjump")
		return

	if Input.is_action_just_pressed("move_down"):
		player.register_down_press()
		state_machine.transition_to("crouch")
		return

	player.update_facing(direction)
	player.velocity.x = direction * player.walk_speed

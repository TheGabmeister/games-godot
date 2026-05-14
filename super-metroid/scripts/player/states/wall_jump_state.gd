extends PlayerState


func enter() -> void:
	player.set_collision_shape("standing")
	player.set_sprite_mode(false)
	player.samus_sprite.play("spin_jump")

	var spin_state: PlayerState = state_machine.states.get("spinjump")
	var wall_dir := Vector2.ZERO
	if spin_state:
		wall_dir = spin_state.wall_normal

	player.velocity.y = player.wall_jump_velocity.y
	if wall_dir != Vector2.ZERO:
		player.velocity.x = wall_dir.x * player.wall_jump_velocity.x
		player.update_facing(wall_dir.x)
	else:
		player.velocity.x = player.facing_direction * player.wall_jump_velocity.x

	state_machine.transition_to("spinjump")


func update(_delta: float) -> void:
	pass

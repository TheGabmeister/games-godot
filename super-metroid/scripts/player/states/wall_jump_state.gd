extends PlayerState


func enter() -> void:
	player.set_collision_shape(PlayerConsts.SHAPE_STANDING)
	player.set_sprite_mode(false)
	player.player_sprite.play(PlayerConsts.ANIM_SPIN_JUMP)

	var wall_dir := player.last_wall_normal

	player.velocity.y = player.wall_jump_velocity.y
	if wall_dir != Vector2.ZERO:
		player.velocity.x = wall_dir.x * player.wall_jump_velocity.x
		player.update_facing(wall_dir.x)
	else:
		player.velocity.x = player.facing_direction * player.wall_jump_velocity.x

	state_machine.transition_to(PlayerConsts.STATE_SPIN_JUMP)


func update(_delta: float) -> void:
	pass

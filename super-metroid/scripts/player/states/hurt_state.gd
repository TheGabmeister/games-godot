extends PlayerState

const HURT_DURATION: float = 0.3

var _timer: float = 0.0


func enter() -> void:
	player.set_collision_shape(PlayerConsts.SHAPE_STANDING)
	player.set_sprite_mode(false)
	player.player_sprite.play(PlayerConsts.ANIM_HURT)
	_timer = 0.0
	player.velocity.x = -player.facing_direction * player.knockback_velocity.x
	player.velocity.y = player.knockback_velocity.y


func update(delta: float) -> void:
	player.apply_gravity(delta)
	_timer += delta
	player.velocity.x = move_toward(player.velocity.x, 0.0, player.walk_speed * delta * 3.0)
	if _timer >= HURT_DURATION:
		if player.is_on_floor():
			state_machine.transition_to(PlayerConsts.STATE_IDLE)
		else:
			state_machine.transition_to(PlayerConsts.STATE_FALL)

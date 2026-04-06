extends "res://scripts/player/player_states/player_state.gd"

const _timing := preload("res://resources/config/level_timing_default.tres")

var _death_timer: float = 0.0
var _has_bounced: bool = false


func enter() -> void:
	_death_timer = 0.0
	_has_bounced = false
	player.velocity = Vector2.ZERO
	player.set_physics_process(false)
	player.set_collision_layer(0)
	player.set_collision_mask(0)


func process_frame(delta: float) -> void:
	_death_timer += delta

	if _death_timer >= _timing.death_bounce_delay and not _has_bounced:
		_has_bounced = true
		player.velocity.y = _timing.death_bounce_velocity

	if _has_bounced:
		player.velocity.y += _timing.death_gravity * delta
		player.global_position += player.velocity * delta

	if _death_timer >= _timing.death_duration:
		GameManager.lose_life()

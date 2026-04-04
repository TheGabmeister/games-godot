extends "res://scripts/player/player_states/player_state.gd"

var _death_timer: float = 0.0
var _has_bounced: bool = false
const DEATH_BOUNCE_VELOCITY := -300.0
const DEATH_GRAVITY := 600.0
const DEATH_DURATION := 3.0


func enter() -> void:
	_death_timer = 0.0
	_has_bounced = false
	player.velocity = Vector2.ZERO
	player.set_physics_process(false)
	# Brief pause before the death bounce
	player.set_collision_layer(0)
	player.set_collision_mask(0)


func process_frame(delta: float) -> void:
	_death_timer += delta

	if _death_timer >= 0.5 and not _has_bounced:
		_has_bounced = true
		player.velocity.y = DEATH_BOUNCE_VELOCITY

	if _has_bounced:
		player.velocity.y += DEATH_GRAVITY * delta
		player.global_position += player.velocity * delta

	if _death_timer >= DEATH_DURATION:
		GameManager.lose_life()

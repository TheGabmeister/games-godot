extends BasePlayerState

var _fall_timer: float = 0.0
const FALL_DURATION := 0.5
const FALL_DAMAGE := 2


func enter(msg: Dictionary = {}) -> void:
	super.enter(msg)
	_fall_timer = 0.0
	player.velocity = Vector2.ZERO
	AudioManager.play_sfx(&"fall")

	# Shrink tween
	var tween := player.create_tween()
	tween.tween_property(player.player_body, "scale", Vector2(0.1, 0.1), FALL_DURATION * 0.6)


func update(delta: float) -> void:
	_fall_timer += delta
	if _fall_timer >= FALL_DURATION:
		_respawn()


func _respawn() -> void:
	# Reset visual scale
	player.player_body.scale = Vector2.ONE

	# Respawn at last safe position
	player.global_position = player.last_safe_position

	# Apply damage
	PlayerState.apply_damage(FALL_DAMAGE)

	# If lethal, go to Death instead of Idle
	if PlayerState.current_health <= 0:
		state_machine.transition_to(&"Death")
		return

	# Landing squash
	var tween := player.create_tween()
	tween.tween_property(player.player_body, "scale", Vector2(1.3, 0.6), 0.05)
	tween.tween_property(player.player_body, "scale", Vector2.ONE, 0.15)

	state_machine.transition_to(&"Idle")

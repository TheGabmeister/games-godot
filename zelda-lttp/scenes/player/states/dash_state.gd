extends BasePlayerState

var _dash_timer: float = 0.0
const DASH_DURATION := 0.6


func enter(msg: Dictionary = {}) -> void:
	super.enter(msg)
	_dash_timer = 0.0
	AudioManager.play_sfx(&"dash_start")


func physics_update(delta: float) -> void:
	_dash_timer += delta

	var direction: Vector2 = player.facing_direction.normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.DOWN
	player.velocity = direction * player.speed * player.dash_speed_multiplier
	player.move_and_slide()

	if _dash_timer >= DASH_DURATION:
		var input := get_movement_input()
		if input != Vector2.ZERO:
			state_machine.transition_to(&"Walk")
		else:
			state_machine.transition_to(&"Idle")


func exit() -> void:
	player.velocity = Vector2.ZERO

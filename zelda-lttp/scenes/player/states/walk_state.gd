extends BasePlayerState

var _safe_position_timer: float = 0.0
const SAFE_POSITION_INTERVAL := 0.5


func enter(msg: Dictionary = {}) -> void:
	super.enter(msg)
	_safe_position_timer = 0.0


func physics_update(delta: float) -> void:
	var input := get_movement_input()
	if input == Vector2.ZERO:
		state_machine.transition_to(&"Idle")
		return

	player.update_facing(input)
	player.move_input = input
	player.velocity = input * player.speed
	player.move_and_slide()

	# Track safe position periodically
	_safe_position_timer += delta
	if _safe_position_timer >= SAFE_POSITION_INTERVAL:
		_safe_position_timer = 0.0
		if player.is_on_floor() or true:  # 2D: always grounded
			player.last_safe_position = player.global_position


func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("action_sword"):
		state_machine.transition_to(&"Attack")
	elif event.is_action_pressed("action_dash"):
		if PlayerState.has_upgrade(&"boots"):
			state_machine.transition_to(&"Dash")

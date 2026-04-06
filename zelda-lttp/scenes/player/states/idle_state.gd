extends BasePlayerState


func enter(msg: Dictionary = {}) -> void:
	super.enter(msg)
	player.velocity = Vector2.ZERO

	# Check input buffer
	var buffered := consume_buffer()
	if buffered == &"action_sword":
		state_machine.transition_to(&"Attack")
		return


func physics_update(_delta: float) -> void:
	if is_gameplay_paused():
		return
	var input := get_movement_input()
	if input != Vector2.ZERO:
		state_machine.transition_to(&"Walk")
		return


func handle_input(event: InputEvent) -> void:
	if is_gameplay_paused():
		return
	if event.is_action_pressed("action_sword"):
		state_machine.transition_to(&"Attack")
	elif event.is_action_pressed("action_item"):
		state_machine.transition_to(&"ItemUse")
	elif event.is_action_pressed("interact"):
		(player as Player).try_interact()
	elif event.is_action_pressed("action_dash"):
		if PlayerState.has_upgrade(&"boots"):
			state_machine.transition_to(&"Dash")

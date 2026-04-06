extends BasePlayerState

const SWIM_SPEED_FACTOR := 0.6


func enter(msg: Dictionary = {}) -> void:
	super.enter(msg)
	player.player_body.queue_redraw()


func physics_update(_delta: float) -> void:
	var input := get_movement_input()
	if input == Vector2.ZERO:
		player.velocity = Vector2.ZERO
	else:
		player.update_facing(input)
		player.move_input = input
		player.velocity = input * player.speed * SWIM_SPEED_FACTOR
		player.move_and_slide()


func exit() -> void:
	player.player_body.queue_redraw()

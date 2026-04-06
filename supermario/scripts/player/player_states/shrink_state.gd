extends "res://scripts/player/player_states/player_state.gd"


var _timer: float = 0.0
var _source_state_name: StringName = &""
var _source_velocity: Vector2 = Vector2.ZERO


func enter() -> void:
	_timer = 0.0
	_source_state_name = state_machine.previous_state_name
	_source_velocity = player.velocity
	player.velocity = Vector2.ZERO

	# Pause gameplay — enemies, items, timer all freeze
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	player.get_tree().paused = true


func exit() -> void:
	# Unpause gameplay
	player.get_tree().paused = false
	player.process_mode = Node.PROCESS_MODE_INHERIT

	player.velocity = _source_velocity
	player.drawer.power_state = GameManager.current_power_state
	player._update_collision_shape()
	player._start_invincibility()


func process_frame(delta: float) -> void:
	_timer += delta

	# Flicker between big and small drawing
	var flicker_cycle: float = _timer * player.effects.grow_flicker_rate
	var show_small := int(flicker_cycle) % 2 == 0
	player.drawer.power_state = GameManager.PowerState.SMALL if show_small else GameManager.PowerState.BIG

	if _timer >= player.effects.grow_shrink_duration:
		var return_state: StringName = _source_state_name
		if return_state == &"JumpState" and _source_velocity.y >= 0.0:
			return_state = &"FallState"
		if return_state == &"GrowState" or return_state == &"ShrinkState":
			return_state = &"IdleState"
		state_machine.transition_to(return_state)

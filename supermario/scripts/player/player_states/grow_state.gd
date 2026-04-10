extends "res://scripts/player/player_states/player_state.gd"

const PowerUpEffect := preload("res://scripts/effects/power_up_effect.gd")

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

	# Spawn pickup ring effect
	var ring := Node2D.new()
	ring.set_script(PowerUpEffect)
	ring.process_mode = Node.PROCESS_MODE_ALWAYS
	ring.global_position = player.global_position + Vector2(0, -8)
	ring.z_index = 5
	player.get_parent().add_child(ring)


func exit() -> void:
	# Unpause gameplay
	player.get_tree().paused = false
	player.process_mode = Node.PROCESS_MODE_INHERIT

	player.velocity = _source_velocity
	player.drawer.power_state = GameManager.current_power_state
	player.update_collision_shape()


func process_frame(delta: float) -> void:
	_timer += delta

	# Flicker between small and big drawing
	var flicker_cycle: float = _timer * player.effects.grow_flicker_rate
	var show_big := int(flicker_cycle) % 2 == 0
	player.drawer.power_state = GameManager.current_power_state if show_big else GameManager.PowerState.SMALL

	if _timer >= player.effects.grow_shrink_duration:
		var return_state: StringName = _source_state_name
		if return_state == &"JumpState" and _source_velocity.y >= 0.0:
			return_state = &"FallState"
		if return_state == &"GrowState" or return_state == &"ShrinkState":
			return_state = &"IdleState"
		state_machine.transition_to(return_state)

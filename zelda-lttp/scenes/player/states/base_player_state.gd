class_name BasePlayerState extends State

var player: CharacterBody2D

# Input buffer
var _buffered_action: StringName = &""
var _buffer_timer: float = 0.0
const INPUT_BUFFER_TIME := 0.1


func enter(msg: Dictionary = {}) -> void:
	if not player and owner:
		player = owner as CharacterBody2D


func update(delta: float) -> void:
	if _buffer_timer > 0.0:
		_buffer_timer -= delta
		if _buffer_timer <= 0.0:
			_buffered_action = &""


func buffer_action(action: StringName) -> void:
	_buffered_action = action
	_buffer_timer = INPUT_BUFFER_TIME


func consume_buffer() -> StringName:
	var action := _buffered_action
	_buffered_action = &""
	_buffer_timer = 0.0
	return action


func get_movement_input() -> Vector2:
	var input := Vector2.ZERO
	input.x = Input.get_axis("move_left", "move_right")
	input.y = Input.get_axis("move_up", "move_down")
	if input.length() > 1.0:
		input = input.normalized()
	return input


func is_gameplay_paused() -> bool:
	return player and player.get_tree().paused and state_machine.current_state != state_machine.states.get(&"ItemGet")

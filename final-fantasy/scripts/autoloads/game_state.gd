extends Node

signal state_changed(old_state: State, new_state: State)

enum State { TITLE, FIELD, DIALOGUE, BATTLE, CUTSCENE, MENU }

var current: State = State.TITLE
var spawn_position := Vector2.ZERO
var has_spawn_override := false

func transition(new_state: State) -> void:
	if new_state == current:
		return
	var old := current
	current = new_state
	state_changed.emit(old, new_state)

func is_state(state: State) -> bool:
	return current == state

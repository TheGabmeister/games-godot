extends Node

enum State { FIELD, DIALOGUE, BATTLE }

signal state_changed(new_state: State)

var current: State = State.FIELD

func change(new_state: State) -> void:
	current = new_state
	state_changed.emit(new_state)

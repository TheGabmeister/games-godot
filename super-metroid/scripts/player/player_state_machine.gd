class_name PlayerStateMachine
extends Node

var current_state: PlayerState
var player: Player
var states: Dictionary = {}


func init(p: Player) -> void:
	player = p
	for child in get_children():
		if child is PlayerState:
			states[child.name.to_lower()] = child
			child.player = player
			child.state_machine = self
	transition_to("idle")


func handle_input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(event)


func update(delta: float) -> void:
	if current_state:
		current_state.update(delta)


func transition_to(state_name: String) -> void:
	var next_state: PlayerState = states.get(state_name)
	if not next_state:
		push_warning("State not found: " + state_name)
		return
	if current_state:
		current_state.exit()
	current_state = next_state
	current_state.enter()

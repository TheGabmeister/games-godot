extends Node

var current_state: Node
var previous_state_name: StringName = &""
var player: CharacterBody2D


func _ready() -> void:
	player = owner as CharacterBody2D
	for child in get_children():
		if child.get_script() != null:
			child.player = player
			child.state_machine = self
	current_state = get_child(0)
	if current_state and current_state.get_script() != null:
		current_state.enter()


func _unhandled_input(event: InputEvent) -> void:
	current_state.process_input(event)


func _process(delta: float) -> void:
	current_state.process_frame(delta)


func _physics_process(delta: float) -> void:
	current_state.process_physics(delta)


func transition_to(state_name: StringName) -> void:
	var new_state := get_node(NodePath(state_name))
	if new_state == null or new_state == current_state:
		return
	previous_state_name = current_state.name
	current_state.exit()
	current_state = new_state
	current_state.enter()

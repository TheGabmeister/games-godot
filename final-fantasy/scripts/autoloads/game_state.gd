extends Node

signal state_changed(old_state: State, new_state: State)

enum State { TITLE, FIELD, DIALOGUE, BATTLE, CUTSCENE, MENU }

var current: State = State.TITLE

const _WORLD_SESSION_PATH := "res://_scenes/world_session.tscn"

func _ready() -> void:
	_check_bootstrap.call_deferred()

func _check_bootstrap() -> void:
	if not get_tree().get_nodes_in_group(Groups.WORLD_SESSION).is_empty():
		return
	var scene := get_tree().current_scene
	if not scene is LevelData:
		return
	var level_path := scene.scene_file_path
	var ws_scene: PackedScene = load(_WORLD_SESSION_PATH)
	var ws: Node = ws_scene.instantiate()
	ws.set(&"initial_level_path", level_path)
	get_tree().root.add_child(ws)
	get_tree().current_scene = ws
	scene.queue_free()

func transition(new_state: State) -> void:
	if new_state == current:
		return
	var old := current
	current = new_state
	state_changed.emit(old, new_state)

func is_state(state: State) -> bool:
	return current == state

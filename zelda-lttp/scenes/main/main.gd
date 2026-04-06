extends Node

@onready var world: Node2D = $World
@onready var transition_overlay: CanvasLayer = $TransitionOverlay
@onready var pause_subscreen: Control = $PauseLayer/PauseSubscreen

var _player: Player = null

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")


func _ready() -> void:
	SceneManager.set_world_node(world)

	# Create persistent player
	_player = PLAYER_SCENE.instantiate()
	SceneManager.set_player(_player)

	# Load initial room if registry has start_house, otherwise load debug room
	if SceneManager.room_registry.has(&"start_house"):
		SceneManager.load_room(&"start_house")
	elif SceneManager.room_registry.has(&"debug_room"):
		SceneManager.load_room(&"debug_room")
	else:
		# Direct load debug room if no registry entries
		var debug_path := "res://debug/debug_room.tscn"
		if ResourceLoader.exists(debug_path):
			SceneManager.load_room_direct(debug_path)
		else:
			push_warning("[Main] No rooms available to load")

	# Connect transition signal
	EventBus.room_transition_requested.connect(_on_room_transition_requested)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_toggle_pause()
		get_viewport().set_input_as_handled()


func _toggle_pause() -> void:
	if get_tree().paused:
		pause_subscreen.close()
		get_tree().paused = false
	else:
		get_tree().paused = true
		pause_subscreen.open()


func _on_room_transition_requested(target_room_id: StringName, entry_point: StringName) -> void:
	SceneManager.load_room(target_room_id, entry_point)

extends Node

@onready var world: Node2D = $World
@onready var transition_overlay: CanvasLayer = $TransitionOverlay
@onready var pause_subscreen: Control = $PauseLayer/PauseSubscreen

var _player: Player = null

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")


func _ready() -> void:
	SceneManager.set_world_node(world)
	SceneManager.set_transition_overlay(transition_overlay)

	# Create persistent player
	_player = PLAYER_SCENE.instantiate()
	SceneManager.set_player(_player)

	# Load initial room
	if SceneManager.room_registry.has(&"overworld_0_0"):
		SceneManager.load_room(&"overworld_0_0")
	elif SceneManager.room_registry.has(&"start_house"):
		SceneManager.load_room(&"start_house")
	elif SceneManager.room_registry.has(&"debug_room"):
		SceneManager.load_room(&"debug_room")
	else:
		var debug_path := "res://debug/debug_room.tscn"
		if ResourceLoader.exists(debug_path):
			SceneManager.load_room_direct(debug_path)
		else:
			push_warning("[Main] No rooms available to load")

	# Connect signals
	EventBus.room_transition_requested.connect(_on_room_transition_requested)
	EventBus.world_switch_requested.connect(_on_world_switch_requested)


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
	var transition_style := &"fade"
	# Check if the door passed a style via metadata
	if _player and _player.has_meta("transition_style"):
		transition_style = _player.get_meta("transition_style")
		_player.remove_meta("transition_style")
	SceneManager.load_room_with_transition(target_room_id, entry_point, transition_style)


func _on_world_switch_requested(target_world_type: StringName) -> void:
	SceneManager.switch_world(target_world_type)

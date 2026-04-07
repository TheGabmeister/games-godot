extends Node

@onready var world: Node2D = $World
@onready var transition_overlay: CanvasLayer = $TransitionOverlay
@onready var pause_subscreen: Control = $PauseLayer/PauseSubscreen
@onready var post_process_rect: ColorRect = $PostProcessLayer/ColorRect

var _player: Player = null
var _title_screen: Control = null
var _in_title_screen: bool = true
var _play_time_seconds: float = 0.0

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const TITLE_SCREEN_SCENE := preload("res://scenes/ui/title_screen.tscn")


func _ready() -> void:
	SceneManager.set_world_node(world)
	SceneManager.set_transition_overlay(transition_overlay)
	SceneManager.set_post_process_rect(post_process_rect)

	# Connect signals
	EventBus.room_transition_requested.connect(_on_room_transition_requested)
	EventBus.world_switch_requested.connect(_on_world_switch_requested)

	# Show title screen
	_show_title_screen()


func _process(delta: float) -> void:
	if not _in_title_screen:
		_play_time_seconds += delta


func _show_title_screen() -> void:
	_in_title_screen = true
	get_tree().paused = true

	_title_screen = TITLE_SCREEN_SCENE.instantiate()
	_title_screen.new_game_requested.connect(_on_new_game)
	_title_screen.continue_requested.connect(_on_continue)
	$HUDLayer.visible = false
	add_child(_title_screen)


func _on_new_game(slot: int) -> void:
	_title_screen.queue_free()
	_title_screen = null
	_in_title_screen = false
	$HUDLayer.visible = true

	# Reset game state
	PlayerState.reset()
	GameManager.reset()
	GameManager.current_save_slot = slot
	_play_time_seconds = 0.0

	# Create player and start
	_create_player()
	_load_starting_room()
	get_tree().paused = false


func _on_continue(slot: int) -> void:
	_title_screen.queue_free()
	_title_screen = null
	_in_title_screen = false
	$HUDLayer.visible = true

	# Create player first, then load save
	_create_player()
	SaveManager.load_game(slot)
	_play_time_seconds = float(SaveManager.get_slot_metadata(slot).get("play_time_seconds", 0))
	get_tree().paused = false


func _create_player() -> void:
	if _player:
		if _player.get_parent():
			_player.get_parent().remove_child(_player)
		_player.queue_free()
	_player = PLAYER_SCENE.instantiate()
	SceneManager.set_player(_player)


func _load_starting_room() -> void:
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


func _unhandled_input(event: InputEvent) -> void:
	if _in_title_screen:
		return
	if event.is_action_pressed("pause"):
		_toggle_pause()
		get_viewport().set_input_as_handled()


func _toggle_pause() -> void:
	if Cutscene.is_playing:
		return
	if get_tree().paused:
		pause_subscreen.close()
		get_tree().paused = false
	else:
		get_tree().paused = true
		pause_subscreen.open()


func _on_room_transition_requested(target_room_id: StringName, entry_point: StringName) -> void:
	var transition_style := &"fade"
	if _player and _player.has_meta("transition_style"):
		transition_style = _player.get_meta("transition_style")
		_player.remove_meta("transition_style")
	SceneManager.load_room_with_transition(target_room_id, entry_point, transition_style)


func _on_world_switch_requested(target_world_type: StringName) -> void:
	SceneManager.switch_world(target_world_type)


func get_play_time() -> int:
	return int(_play_time_seconds)

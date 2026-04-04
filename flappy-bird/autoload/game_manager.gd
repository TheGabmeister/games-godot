extends Node

signal game_started
signal game_over
signal score_changed(new_score: int)

var score: int = 0
var is_playing: bool = false
var is_game_over: bool = false


func _ready() -> void:
	_setup_input_actions()


func _setup_input_actions() -> void:
	if not InputMap.has_action("flap"):
		InputMap.add_action("flap")

		var key_event := InputEventKey.new()
		key_event.physical_keycode = KEY_SPACE
		InputMap.action_add_event("flap", key_event)

		var mouse_event := InputEventMouseButton.new()
		mouse_event.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("flap", mouse_event)


func start_game() -> void:
	score = 0
	is_playing = true
	is_game_over = false
	score_changed.emit(score)
	game_started.emit()


func end_game() -> void:
	if is_game_over:
		return
	is_playing = false
	is_game_over = true
	game_over.emit()


func add_score() -> void:
	if not is_playing:
		return
	score += 1
	score_changed.emit(score)

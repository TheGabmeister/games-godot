extends CanvasLayer

@onready var _panel: ColorRect = $Panel
@onready var _label: Label = $Panel/Label

var _is_paused: bool = false


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		if _is_paused:
			unpause()
		elif GameManager.game_state == GameManager.GameState.PLAYING:
			pause()
		get_viewport().set_input_as_handled()


func pause() -> void:
	_is_paused = true
	visible = true
	get_tree().paused = true
	GameManager.set_game_state(GameManager.GameState.PAUSED)
	AudioManager.set_music_ducked(true)


func unpause() -> void:
	_is_paused = false
	visible = false
	get_tree().paused = false
	GameManager.set_game_state(GameManager.GameState.PLAYING)
	AudioManager.set_music_ducked(false)

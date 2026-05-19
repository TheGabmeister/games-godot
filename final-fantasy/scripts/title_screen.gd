extends Control

@export var music: AudioStream
@export var next_scene: PackedScene

func _ready() -> void:
	GameState.transition(GameState.State.TITLE)
	if music:
		MusicManager.play(music)

func _input(event: InputEvent) -> void:
	if not GameState.is_state(GameState.State.TITLE):
		return
	if event.is_action_pressed("confirm"):
		MusicManager.stop()
		if next_scene:
			get_tree().change_scene_to_packed(next_scene)

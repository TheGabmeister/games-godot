extends Control

@export var music: AudioStream
@export var next_scene: PackedScene

func _ready() -> void:
	if music:
		MusicManager.play(&"title", music)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("confirm"):
		MusicManager.stop()
		if next_scene:
			get_tree().change_scene_to_packed(next_scene)

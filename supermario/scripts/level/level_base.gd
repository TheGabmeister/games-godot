extends Node2D

@export var player_scene: PackedScene
@export var level_music: AudioStream

var player: CharacterBody2D


func _ready() -> void:
	EventBus.level_started.connect(_on_level_started)
	EventBus.level_music_requested.connect(_request_level_music)
	_spawn_player()


func _spawn_player() -> void:
	var start := get_node_or_null("PlayerStart") as Marker2D
	player = player_scene.instantiate()
	if start:
		player.position = start.position
	else:
		push_warning("No PlayerStart found — spawning player at scene origin")
	add_child(player)


func _on_level_started(_world: int, _level: int) -> void:
	_request_level_music()


func _request_level_music() -> void:
	if level_music != null:
		EventBus.music_requested.emit(level_music)
	else:
		EventBus.music_stop_requested.emit()



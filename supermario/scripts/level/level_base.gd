extends Node2D

const TILE_SIZE := 32
const LEVEL_HEIGHT := 14  # tiles

@export var level_width_tiles: int = 212
@export var level_music: AudioStream

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D


func _ready() -> void:
	EventBus.level_started.connect(_on_level_started)
	EventBus.level_music_requested.connect(_request_level_music)
	camera = player.get_node("Camera2D") as Camera2D
	_setup_camera()


func _on_level_started(_world: int, _level: int) -> void:
	_request_level_music()


func _request_level_music() -> void:
	if level_music != null:
		EventBus.music_requested.emit(level_music)
	else:
		EventBus.music_stop_requested.emit()


func _setup_camera() -> void:
	camera.limit_left = 0
	camera.limit_right = level_width_tiles * TILE_SIZE
	camera.limit_top = -TILE_SIZE * 2
	camera.limit_bottom = LEVEL_HEIGHT * TILE_SIZE + TILE_SIZE * 2
	camera.position_smoothing_speed = 8.0



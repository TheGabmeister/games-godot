extends Node2D

const TilesetBuilder := preload("res://scripts/level/tileset_builder.gd")

const TILE_SIZE := 16
const LEVEL_HEIGHT := 14
const LEVEL_WIDTH := 170  # tiles

@export var level_music: AudioStream

@onready var tilemap: TileMapLayer = $TileMapLayer_Ground
@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D


func _ready() -> void:
	EventBus.level_started.connect(_on_level_started)
	EventBus.level_music_requested.connect(_request_level_music)
	camera = player.get_node("Camera2D") as Camera2D
	tilemap.tile_set = TilesetBuilder.create_tileset(Palette.UNDERGROUND_DARK, Palette.UNDERGROUND_BASE)
	_setup_camera()
	_paint_terrain()
	# Level boot and run-state are owned by GameManager._enter_level().


func _on_level_started(_world: int, _level: int) -> void:
	_request_level_music()


func _request_level_music() -> void:
	if level_music != null:
		EventBus.music_requested.emit(level_music)
	else:
		EventBus.music_stop_requested.emit()


func _setup_camera() -> void:
	camera.limit_left = 0
	camera.limit_right = LEVEL_WIDTH * TILE_SIZE
	camera.limit_top = -TILE_SIZE * 2
	camera.limit_bottom = LEVEL_HEIGHT * TILE_SIZE + TILE_SIZE * 2
	camera.position_smoothing_speed = 8.0


func _paint_terrain() -> void:
	# Floor: rows 12-13
	for x in LEVEL_WIDTH:
		if _is_pit(x):
			continue
		tilemap.set_cell(Vector2i(x, 12), 0, Vector2i(0, 0))
		tilemap.set_cell(Vector2i(x, 13), 0, Vector2i(1, 0))

	# Ceiling: rows 0-1
	for x in LEVEL_WIDTH:
		tilemap.set_cell(Vector2i(x, 0), 0, Vector2i(1, 0))
		tilemap.set_cell(Vector2i(x, 1), 0, Vector2i(0, 0))

	# Raised platforms
	_paint_platform(20, 30, 8)   # floating platform
	_paint_platform(50, 58, 6)   # higher platform
	_paint_platform(80, 90, 8)   # floating platform
	_paint_platform(110, 118, 6) # higher platform
	_paint_platform(130, 140, 8) # floating platform

	# Staircase to exit at the end
	for i in 4:
		for row in range(12 - 1 - i, 12):
			tilemap.set_cell(Vector2i(155 + i, row), 0, Vector2i(1, 0))


func _is_pit(x: int) -> bool:
	# Pits in the underground
	if x >= 65 and x <= 67:
		return true
	if x >= 100 and x <= 102:
		return true
	return false


func _paint_platform(start_x: int, end_x: int, row: int) -> void:
	for x in range(start_x, end_x):
		tilemap.set_cell(Vector2i(x, row), 0, Vector2i(0, 0))



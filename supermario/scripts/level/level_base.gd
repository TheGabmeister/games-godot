extends Node2D

const TilesetBuilder := preload("res://scripts/level/tileset_builder.gd")

const TILE_SIZE := 16
const LEVEL_HEIGHT := 14  # tiles

@export var level_width_tiles: int = 212
@export var ground_row: int = 12  # first ground row (0-indexed from top)
@export var level_music: AudioStream

@onready var tilemap: TileMapLayer = $TileMapLayer_Ground
@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D


func _ready() -> void:
	EventBus.level_started.connect(_on_level_started)
	EventBus.level_music_requested.connect(_request_level_music)
	camera = player.get_node("Camera2D") as Camera2D
	tilemap.tile_set = TilesetBuilder.create_tileset(Palette.GROUND_GREEN, Palette.GROUND_BROWN)
	_setup_camera()
	_paint_terrain()
	# Level boot, run-state resets, intro overlay, timer start, and
	# respawn reloads are all driven by GameManager._enter_level(). This
	# script only builds the level; it does not drive the flow.


func _on_level_started(_world: int, _level: int) -> void:
	_request_level_music()


func _request_level_music() -> void:
	if level_music != null:
		EventBus.music_requested.emit(level_music)
	else:
		EventBus.music_stop_requested.emit()


func _setup_camera() -> void:
	# Horizontal follow only, fixed Y
	camera.limit_left = 0
	camera.limit_right = level_width_tiles * TILE_SIZE
	camera.limit_top = -TILE_SIZE * 2
	camera.limit_bottom = LEVEL_HEIGHT * TILE_SIZE + TILE_SIZE * 2
	camera.position_smoothing_speed = 8.0


func _paint_terrain() -> void:
	# Paint ground: rows 12 and 13 across the full level, skipping pits
	var pits: Array[Vector2i] = _get_pits()
	for x in level_width_tiles:
		if _is_pit(x, pits):
			continue
		# Row 12: ground top
		tilemap.set_cell(Vector2i(x, ground_row), 0, Vector2i(0, 0))
		# Row 13: ground fill
		tilemap.set_cell(Vector2i(x, ground_row + 1), 0, Vector2i(1, 0))

	# Paint staircases
	_paint_stairs()


func _get_pits() -> Array[Vector2i]:
	# Each pit defined as Vector2i(start_x, end_x) inclusive
	return [
		Vector2i(91, 92),
		Vector2i(112, 114),
		Vector2i(158, 160),
		Vector2i(182, 183),
	]


func _is_pit(x: int, pits: Array[Vector2i]) -> bool:
	for pit in pits:
		if x >= pit.x and x <= pit.y:
			return true
	return false


func _paint_stairs() -> void:
	# Section 5: staircase up at X 178-181
	for i in 4:
		for row in range(ground_row - 1 - i, ground_row):
			tilemap.set_cell(Vector2i(178 + i, row), 0, Vector2i(1, 0))

	# Section 5: staircase down at X 184-187
	for i in 4:
		for row in range(ground_row - 1 - (3 - i), ground_row):
			tilemap.set_cell(Vector2i(184 + i, row), 0, Vector2i(1, 0))

	# Section 6: final staircase at X 198-205 (1-8 blocks high)
	for i in 8:
		for row in range(ground_row - 1 - i, ground_row):
			tilemap.set_cell(Vector2i(198 + i, row), 0, Vector2i(1, 0))



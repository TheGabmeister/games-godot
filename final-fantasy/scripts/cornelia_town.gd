extends Node2D

const TOWN_MUSIC := preload("res://music/town_theme.ogg")

# Tile atlas coords: Vector2i(col, row)
const T: Dictionary[String, Vector2i] = {
	"grass":      Vector2i(0, 0),
	"stone":      Vector2i(1, 0),
	"wood":       Vector2i(2, 0),
	"sand":       Vector2i(3, 0),
	"door":       Vector2i(4, 0),
	"dark_floor": Vector2i(5, 0),
	"flowers":    Vector2i(6, 0),
	"grass_dark": Vector2i(7, 0),
	"wall":       Vector2i(0, 1),
	"building":   Vector2i(1, 1),
	"roof":       Vector2i(2, 1),
	"water":      Vector2i(3, 1),
	"counter":    Vector2i(4, 1),
	"fence":      Vector2i(5, 1),
	"roof_top":   Vector2i(6, 1),
	"wall_top":   Vector2i(7, 1),
	"well":       Vector2i(0, 2),
	"sign":       Vector2i(1, 2),
	"stairs":     Vector2i(2, 2),
	"water_edge": Vector2i(3, 2),
	"black":      Vector2i(4, 2),
	"tree":       Vector2i(5, 2),
	"bush":       Vector2i(6, 2),
	"carpet":     Vector2i(0, 3),
	"throne":     Vector2i(1, 3),
	"pillar":     Vector2i(2, 3),
	"chest":      Vector2i(3, 3),
}

# Map legend (single chars for compact layout)
const LEGEND := {
	".": "grass",
	"s": "stone",
	"w": "wood",
	"d": "door",
	"W": "wall",
	"B": "building",
	"R": "roof",
	"~": "water",
	"C": "counter",
	"F": "fence",
	"r": "roof_top",
	"T": "tree",
	"b": "bush",
	"f": "flowers",
	"g": "grass_dark",
	"E": "water_edge",
	"S": "sign",
	"L": "well",
	"#": "black",
	"K": "dark_floor",
	"P": "pillar",
	"H": "throne",
	"A": "carpet",
	"X": "chest",
	"D": "sand",
}

# 20x15 town layout (fits 1280x960, camera follows player)
const MAP := [
	"T.T...RRRR....RRRR.T",
	"....f.BWWB....BWWB..",
	".s....BWdB.f..BWdB.f",
	".sss..............ss",
	".s.s..RRRR..L...s..s",
	".s....BWWB......ssss",
	"......BWdB.f........",
	"Tsss.........sssss.T",
	"..s...RRRR...s...s..",
	"..s.f.BWWB.f.sdds.b.",
	"..s...BWdB...s...s..",
	"..sssss..sssssssss..",
	"T....f..........f..T",
	"EEEEEEEEEEEEEEEEEEEE",
	"~~~~~~~~~~~~~~~~~~~~~",
]

@onready var tile_map: TileMapLayer = $TileMapLayer
@onready var warrior: CharacterBody2D = $Warrior

func _ready() -> void:
	GameState.transition(GameState.State.FIELD)
	MusicManager.play(TOWN_MUSIC)
	_paint_map()
	if GameState.has_spawn_override:
		warrior.position = GameState.spawn_position
		GameState.has_spawn_override = false

func _paint_map() -> void:
	for y in range(MAP.size()):
		var row: String = MAP[y]
		for x in range(row.length()):
			var ch := row[x]
			if ch == " ":
				continue
			if ch in LEGEND:
				var tile_name: String = LEGEND[ch]
				if tile_name in T:
					tile_map.set_cell(Vector2i(x, y), 0, T[tile_name])

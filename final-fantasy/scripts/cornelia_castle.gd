extends Node2D

const CASTLE_MUSIC := preload("res://music/castle_theme.ogg")

const T: Dictionary[String, Vector2i] = {
	"wall":       Vector2i(0, 1),
	"dark_floor": Vector2i(5, 0),
	"carpet":     Vector2i(0, 3),
	"throne":     Vector2i(1, 3),
	"pillar":     Vector2i(2, 3),
	"door":       Vector2i(4, 0),
}

const LEGEND := {
	"W": "wall",
	"K": "dark_floor",
	"A": "carpet",
	"H": "throne",
	"P": "pillar",
	"d": "door",
}

const MAP := [
	"WWWWWWWWWWWWWWW",
	"WKKKKKKKKKKKKKW",
	"WKPKKKKKKKKKPKW",
	"WKKKKKAAKKKKKKW",
	"WKKKKKAAKKKKKKW",
	"WKPKKKHAKKKKPKW",
	"WKKKKKAAKKKKKKW",
	"WKKKKKAAKKKKKKW",
	"WKPKKKAAKKKKPKW",
	"WKKKKKAAKKKKKKW",
	"WWWWWWWdWWWWWWW",
]

@onready var tile_map: TileMapLayer = $TileMapLayer
@onready var warrior: CharacterBody2D = $Warrior

func _ready() -> void:
	GameState.transition(GameState.State.FIELD)
	MusicManager.play(CASTLE_MUSIC)
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

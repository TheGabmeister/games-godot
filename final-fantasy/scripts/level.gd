extends Node2D

const WARRIOR_SCENE := preload("res://_scenes/warrior.tscn")
const DIALOGUE_BOX_SCENE := preload("res://_scenes/dialogue_box.tscn")
const MAIN_MENU_SCENE := preload("res://_scenes/main_menu.tscn")

@export var music: AudioStream
@export var default_spawn := Vector2(224, 224)

@onready var tile_map: TileMapLayer = $TileMapLayer

func _ready() -> void:
	GameState.transition(GameState.State.FIELD)
	if music:
		MusicManager.play(music)

	var warrior: CharacterBody2D = WARRIOR_SCENE.instantiate()
	if GameState.has_spawn_override:
		warrior.position = GameState.spawn_position
		GameState.has_spawn_override = false
	else:
		warrior.position = default_spawn
	add_child(warrior)

	var camera := Camera2D.new()
	var used := tile_map.get_used_rect()
	var tile_size := tile_map.tile_set.tile_size
	camera.limit_left = used.position.x * tile_size.x
	camera.limit_top = used.position.y * tile_size.y
	camera.limit_right = used.end.x * tile_size.x
	camera.limit_bottom = used.end.y * tile_size.y
	warrior.add_child(camera)

	var dialogue_box: DialogueBox = DIALOGUE_BOX_SCENE.instantiate()
	add_child(dialogue_box)

	var main_menu: MainMenu = MAIN_MENU_SCENE.instantiate()
	add_child(main_menu)

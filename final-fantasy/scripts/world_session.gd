class_name WorldSession
extends Node

@export var warrior_scene: PackedScene
@export var dialogue_box_scene: PackedScene
@export var party_menu_scene: PackedScene
@export var battle_scene_packed: PackedScene
@export_file("*.tscn") var initial_level_path: String

var _warrior: PlayerMovement
var _camera: Camera2D
var _current_level: Node2D
var _party_data: PartyData
var _battle_scene: Node

var _pending_spawn := Vector2.ZERO
var _has_pending_spawn := false

func _ready() -> void:
	add_to_group(Groups.WORLD_SESSION)

	_party_data = PartyData.new()
	_party_data.name = "PartyData"
	add_child(_party_data)

	_warrior = warrior_scene.instantiate()
	add_child(_warrior)
	_warrior.encounter_triggered.connect(_on_encounter_triggered)

	_camera = Camera2D.new()
	_warrior.add_child(_camera)

	var dialogue_box: DialogueBox = dialogue_box_scene.instantiate()
	add_child(dialogue_box)

	var party_menu: PartyMenu = party_menu_scene.instantiate()
	party_menu.party_data = _party_data
	add_child(party_menu)

	if battle_scene_packed:
		_battle_scene = battle_scene_packed.instantiate()
		_battle_scene.set(&"party_data", _party_data)
		var _err: int = _battle_scene.connect(&"battle_ended", Callable(self, &"_on_battle_ended"))
		add_child(_battle_scene)

	_load_level(initial_level_path)

func transition_to_level(scene_path: String, spawn_pos: Vector2) -> void:
	_pending_spawn = spawn_pos
	_has_pending_spawn = true
	_load_level.call_deferred(scene_path)

func _load_level(scene_path: String) -> void:
	if _current_level:
		_current_level.queue_free()
		_current_level = null

	var scene: PackedScene = load(scene_path)
	_current_level = scene.instantiate()
	add_child(_current_level)
	move_child(_current_level, 0)

	var level_data := _current_level as LevelData
	if level_data:
		if level_data.music:
			MusicManager.play(level_data.music)

		if _has_pending_spawn:
			_warrior.position = _pending_spawn
			_has_pending_spawn = false
		else:
			_warrior.position = level_data.default_spawn

		_warrior.encounter_table = level_data.encounter_table
		_warrior.reset_step_counter()

	_update_camera_limits()
	GameState.transition(GameState.State.FIELD)

func _on_battle_ended() -> void:
	var level_data := _current_level as LevelData
	if level_data and level_data.music:
		MusicManager.play(level_data.music)

func _on_encounter_triggered(formation: EncounterFormation) -> void:
	if _battle_scene:
		var level_data := _current_level as LevelData
		var encounter_table: EncounterTable = level_data.encounter_table if level_data else null
		_battle_scene.call(&"start_battle", formation, encounter_table)

func _update_camera_limits() -> void:
	var tile_map := _current_level.find_child("TileMapLayer", false) as TileMapLayer
	if not tile_map:
		return
	var used: Rect2i = tile_map.get_used_rect()
	var tile_size: Vector2i = tile_map.tile_set.tile_size
	_camera.limit_left = used.position.x * tile_size.x
	_camera.limit_top = used.position.y * tile_size.y
	_camera.limit_right = used.end.x * tile_size.x
	_camera.limit_bottom = used.end.y * tile_size.y

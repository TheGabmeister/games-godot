extends Area2D

@export_file("*.tscn") var target_scene_path: String
@export var spawn_position: Vector2

func _ready() -> void:
	var _err := body_entered.connect(_on_body_entered)

func _on_body_entered(_body: Node2D) -> void:
	if not GameState.is_state(GameState.State.FIELD):
		return
	if target_scene_path.is_empty():
		return
	GameState.spawn_position = spawn_position
	GameState.has_spawn_override = true
	var _err := get_tree().change_scene_to_file(target_scene_path)

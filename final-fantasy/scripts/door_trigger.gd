extends Area2D

@export_file("*.tscn") var target_scene_path: String
@export var spawn_position: Vector2

var _armed := false
var _wait_frames := 2

func _ready() -> void:
	var _err := body_entered.connect(_on_body_entered)

func _physics_process(_delta: float) -> void:
	_wait_frames -= 1
	if _wait_frames <= 0:
		_armed = true
		set_physics_process(false)

func _on_body_entered(_body: Node2D) -> void:
	if not _armed:
		return
	if not GameState.is_state(GameState.State.FIELD):
		return
	if target_scene_path.is_empty():
		return
	GameState.spawn_position = spawn_position
	GameState.has_spawn_override = true
	get_tree().change_scene_to_file.call_deferred(target_scene_path)

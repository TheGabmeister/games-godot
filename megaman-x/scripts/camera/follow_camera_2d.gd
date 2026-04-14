extends Camera2D
class_name FollowCamera2D

@export var target_path: NodePath

var _target: Node2D = null


func _ready() -> void:
	if not target_path.is_empty():
		_target = get_node_or_null(target_path) as Node2D


func _process(_delta: float) -> void:
	if _target == null:
		return

	global_position = _target.global_position


func set_target(target: Node2D) -> void:
	_target = target
	global_position = target.global_position


func get_target() -> Node2D:
	return _target

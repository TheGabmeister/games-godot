extends Camera2D

## Side-scrolling camera with look-ahead in the facing direction and a
## ratcheting left limit (no-backtrack). Reads facing from the parent
## character's `Visuals` child and composes screen shake from CameraEffects.

@export var cam_config: Resource  # CameraConfig

var _look_ahead: float = 0.0
var _max_x: float = 0.0
var _player: Node2D
var _visuals: Node2D


func _ready() -> void:
	_player = get_parent() as Node2D
	_visuals = _player.get_node("Visuals") as Node2D


func _process(delta: float) -> void:
	var target_ahead: float = signf(_visuals.scale.x) * cam_config.look_ahead_distance
	_look_ahead = move_toward(_look_ahead, target_ahead, cam_config.look_ahead_speed * delta)
	var shake := CameraEffects.get_shake_offset()
	offset.x = _look_ahead + shake.x
	offset.y = shake.y

	var cam_left: float = _player.global_position.x + _look_ahead - cam_config.no_backtrack_offset
	if cam_left > _max_x:
		_max_x = cam_left
	limit_left = int(_max_x)


func reset_no_backtrack() -> void:
	_max_x = 0.0

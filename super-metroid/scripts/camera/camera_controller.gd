class_name CameraController
extends Camera2D

var target: Node2D
var following: bool = true


func _process(_delta: float) -> void:
	if following and target:
		global_position = target.global_position


func set_room_limits(rect: Rect2) -> void:
	limit_left = int(rect.position.x)
	limit_top = int(rect.position.y)
	limit_right = int(rect.position.x + rect.size.x)
	limit_bottom = int(rect.position.y + rect.size.y)


func clear_limits() -> void:
	limit_left = -100000
	limit_top = -100000
	limit_right = 100000
	limit_bottom = 100000

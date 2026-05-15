@tool
extends Sprite2D

var _blue_closed: Texture2D = preload("res://props/doors/door_blue_closed.png")
var _red_closed: Texture2D = preload("res://props/doors/door_red_closed.png")
var _gray_closed: Texture2D = preload("res://props/doors/door_gray_closed.png")

var _last_type: int = -1
var _last_facing: int = -1


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		set_process(false)
		return
	var parent := get_parent()
	if not parent:
		return
	var dtype: int = parent.get(&"door_type")
	var dfacing: int = parent.get(&"facing")
	if dtype == _last_type and dfacing == _last_facing:
		return
	_last_type = dtype
	_last_facing = dfacing
	match dtype:
		0: texture = _blue_closed
		1: texture = _red_closed
		2: texture = _gray_closed
	flip_h = dfacing == 0
	if dfacing >= 2:
		rotation_degrees = 90.0
	else:
		rotation_degrees = 0.0

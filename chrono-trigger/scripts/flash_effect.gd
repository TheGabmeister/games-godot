extends Node

@export var target: NodePath

var _shader: Shader = preload("res://scripts/flash.gdshader")
var _target_item: CanvasItem

func _ready() -> void:
	_target_item = get_node_or_null(target) as CanvasItem

func flash() -> void:
	if _target_item == null:
		return

	var original_material := _target_item.material
	var flash_material := ShaderMaterial.new()
	flash_material.shader = _shader
	flash_material.set_shader_parameter("flash_amount", 0.0)
	_target_item.material = flash_material

	var tween := create_tween()
	for i in 3:
		tween.tween_property(flash_material, "shader_parameter/flash_amount", 1.0, 0.05)
		tween.tween_property(flash_material, "shader_parameter/flash_amount", 0.0, 0.05)
	tween.finished.connect(func() -> void:
		if is_instance_valid(_target_item):
			_target_item.material = original_material
	)

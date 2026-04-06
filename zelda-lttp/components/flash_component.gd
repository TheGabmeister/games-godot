class_name FlashComponent extends Node

@export var flash_duration: float = 0.08

var _target: CanvasItem = null
var _original_material: Material = null
var _flash_material: ShaderMaterial = null
var _tween: Tween = null


func _ready() -> void:
	# Find the visual node to flash — look for a body/visual child on parent
	var parent := get_parent()
	if parent:
		for child in parent.get_children():
			if child is CanvasItem and child.name.containsn("Body"):
				_target = child
				break
		# Fallback: flash the parent itself if it's a CanvasItem
		if not _target and parent is CanvasItem:
			_target = parent as CanvasItem

	if _target:
		_flash_material = ShaderMaterial.new()
		var shader := load("res://shaders/damage_flash.gdshader") as Shader
		if shader:
			_flash_material.shader = shader


func flash() -> void:
	if not _target or not _flash_material:
		return

	# Cancel any ongoing flash
	if _tween and _tween.is_valid():
		_tween.kill()

	_original_material = _target.material
	_target.material = _flash_material
	_flash_material.set_shader_parameter("flash_amount", 1.0)

	_tween = _target.create_tween()
	_tween.tween_property(_flash_material, "shader_parameter/flash_amount", 0.0, flash_duration)
	_tween.tween_callback(_restore_material)


func _restore_material() -> void:
	if _target:
		_target.material = _original_material

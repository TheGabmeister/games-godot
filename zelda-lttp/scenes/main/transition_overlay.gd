extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect

var _tween: Tween = null


func _ready() -> void:
	color_rect.visible = false
	color_rect.color = Color(0, 0, 0, 0)
	# Ensure shader material is set for iris transitions
	if not color_rect.material:
		var mat := ShaderMaterial.new()
		mat.shader = preload("res://shaders/screen_transition.gdshader")
		mat.set_shader_parameter("progress", 1.0)
		color_rect.material = mat


func fade_out(duration: float = 0.3) -> void:
	_kill_tween()
	color_rect.material = null
	color_rect.visible = true
	color_rect.color = Color(0, 0, 0, 0)
	_tween = create_tween()
	_tween.tween_property(color_rect, "color:a", 1.0, duration)
	await _tween.finished


func fade_in(duration: float = 0.3) -> void:
	_kill_tween()
	color_rect.material = null
	color_rect.visible = true
	color_rect.color = Color(0, 0, 0, 1)
	_tween = create_tween()
	_tween.tween_property(color_rect, "color:a", 0.0, duration)
	await _tween.finished
	color_rect.visible = false


func iris_out(center: Vector2, duration: float = 0.4) -> void:
	_kill_tween()
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/screen_transition.gdshader")
	# Convert center from screen-space pixel coords to UV (0-1)
	var viewport_size := get_viewport().get_visible_rect().size
	var uv_center := center / viewport_size
	mat.set_shader_parameter("center", uv_center)
	mat.set_shader_parameter("progress", 1.0)
	color_rect.material = mat
	color_rect.visible = true
	color_rect.color = Color.WHITE
	_tween = create_tween()
	_tween.tween_method(_set_iris_progress.bind(mat), 1.0, 0.0, duration)
	await _tween.finished


func iris_in(center: Vector2, duration: float = 0.4) -> void:
	_kill_tween()
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/screen_transition.gdshader")
	var viewport_size := get_viewport().get_visible_rect().size
	var uv_center := center / viewport_size
	mat.set_shader_parameter("center", uv_center)
	mat.set_shader_parameter("progress", 0.0)
	color_rect.material = mat
	color_rect.visible = true
	color_rect.color = Color.WHITE
	_tween = create_tween()
	_tween.tween_method(_set_iris_progress.bind(mat), 0.0, 1.0, duration)
	await _tween.finished
	color_rect.visible = false
	color_rect.material = null


func instant_black() -> void:
	_kill_tween()
	color_rect.material = null
	color_rect.visible = true
	color_rect.color = Color(0, 0, 0, 1)


func clear() -> void:
	_kill_tween()
	color_rect.visible = false
	color_rect.color = Color(0, 0, 0, 0)
	color_rect.material = null


func _set_iris_progress(value: float, mat: ShaderMaterial) -> void:
	mat.set_shader_parameter("progress", value)


func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = null

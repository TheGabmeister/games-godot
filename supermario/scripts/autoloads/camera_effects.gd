extends Node

var _shake_intensity: float = 0.0
var _shake_duration: float = 0.0
var _shake_timer: float = 0.0
var _camera: Camera2D


func _process(delta: float) -> void:
	if _shake_timer > 0.0:
		_shake_timer -= delta
		if _camera and is_instance_valid(_camera):
			var decay := _shake_timer / _shake_duration
			var offset := Vector2(
				randf_range(-_shake_intensity, _shake_intensity),
				randf_range(-_shake_intensity, _shake_intensity),
			) * decay
			_camera.offset = offset
		if _shake_timer <= 0.0 and _camera and is_instance_valid(_camera):
			_camera.offset = Vector2.ZERO


func shake(intensity: float, duration: float) -> void:
	_shake_intensity = intensity
	_shake_duration = duration
	_shake_timer = duration


func freeze_frame(duration: float) -> void:
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration * 0.05).timeout
	Engine.time_scale = 1.0


func register_camera(camera: Camera2D) -> void:
	_camera = camera

extends Node

var _shake_intensity: float = 0.0
var _shake_duration: float = 0.0
var _shake_timer: float = 0.0
var _shake_offset: Vector2 = Vector2.ZERO


func get_shake_offset() -> Vector2:
	return _shake_offset


func _process(delta: float) -> void:
	if _shake_timer > 0.0:
		_shake_timer -= delta
		var decay := _shake_timer / _shake_duration
		_shake_offset = Vector2(
			randf_range(-_shake_intensity, _shake_intensity),
			randf_range(-_shake_intensity, _shake_intensity),
		) * decay
		if _shake_timer <= 0.0:
			_shake_offset = Vector2.ZERO
	else:
		_shake_offset = Vector2.ZERO


func shake(intensity: float, duration: float) -> void:
	_shake_intensity = intensity
	_shake_duration = duration
	_shake_timer = duration


func freeze_frame(duration: float) -> void:
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration * 0.05).timeout
	Engine.time_scale = 1.0

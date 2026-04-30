extends Node2D

var _effects: Resource
var _timer: float = 0.0
var _points: int = 0

@onready var _digit_sprites: Array[AnimatedSprite2D] = [
	$Digit0, $Digit1, $Digit2, $Digit3,
]


func setup(points: int, effects_config: Resource) -> void:
	_points = points
	_effects = effects_config
	_build_digits()


func _process(delta: float) -> void:
	if _effects == null:
		return
	_timer += delta
	var t: float = _timer / _effects.score_popup_duration
	if t >= 1.0:
		queue_free()
		return
	position.y -= _effects.score_popup_rise_speed * delta
	modulate.a = 1.0 - t * t


func _build_digits() -> void:
	for sprite in _digit_sprites:
		sprite.visible = false

	var text := str(_points)
	var start_x := -float(text.length()) * 4.0
	for i in mini(text.length(), _digit_sprites.size()):
		var digit := StringName(text[i])
		var sprite := _digit_sprites[i]
		sprite.animation = digit
		sprite.position = Vector2(start_x + i * 8.0 - 16.0, -24.0)
		sprite.scale = Vector2(0.35, 0.35)
		sprite.visible = true

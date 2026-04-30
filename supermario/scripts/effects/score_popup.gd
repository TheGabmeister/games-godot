extends Node2D

const SpriteHelper := preload("res://scripts/visuals/sprite_region_helper.gd")
const SHEET := preload("res://sprites/score_digits_sheet.png")

var _effects: Resource
var _timer: float = 0.0
var _points: int = 0
var _digit_sprites: Array[Sprite2D] = []


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
		sprite.queue_free()
	_digit_sprites.clear()

	var text := str(_points)
	var start_x := -float(text.length()) * 4.0
	for i in text.length():
		var sprite := SpriteHelper.ensure_sprite(self, StringName("Digit%d" % i), SHEET)
		var frame := int(text[i])
		SpriteHelper.set_cell(sprite, frame, 10, Vector2(start_x + i * 8.0 - 16.0, -24.0), Vector2(0.35, 0.35))
		_digit_sprites.append(sprite)

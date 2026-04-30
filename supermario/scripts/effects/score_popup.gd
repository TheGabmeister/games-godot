extends Node2D

const SpriteFramesBuilder := preload("res://scripts/visuals/sprite_frames_builder.gd")
const SHEET := preload("res://sprites/score_digits_sheet.png")
const ANIMATIONS := {
	&"0": {"frames": [0], "fps": 1.0, "loop": false},
	&"1": {"frames": [1], "fps": 1.0, "loop": false},
	&"2": {"frames": [2], "fps": 1.0, "loop": false},
	&"3": {"frames": [3], "fps": 1.0, "loop": false},
	&"4": {"frames": [4], "fps": 1.0, "loop": false},
	&"5": {"frames": [5], "fps": 1.0, "loop": false},
	&"6": {"frames": [6], "fps": 1.0, "loop": false},
	&"7": {"frames": [7], "fps": 1.0, "loop": false},
	&"8": {"frames": [8], "fps": 1.0, "loop": false},
	&"9": {"frames": [9], "fps": 1.0, "loop": false},
}

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
	var frames := SpriteFramesBuilder.build(SHEET, 10, ANIMATIONS)
	for i in mini(text.length(), _digit_sprites.size()):
		var digit := StringName(text[i])
		var sprite := _digit_sprites[i]
		sprite.sprite_frames = frames
		sprite.animation = digit
		sprite.position = Vector2(start_x + i * 8.0 - 16.0, -24.0)
		sprite.scale = Vector2(0.35, 0.35)
		sprite.visible = true

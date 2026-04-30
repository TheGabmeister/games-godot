extends Node2D

const SpriteHelper := preload("res://scripts/visuals/sprite_region_helper.gd")
const SHEET := preload("res://sprites/effects_sheet.png")

var _timer: float = 0.0
var _sprites: Array[Sprite2D] = []
const DURATION := 0.2


func _ready() -> void:
	for i in 6:
		var sprite := SpriteHelper.ensure_sprite(self, StringName("Puff%d" % i), SHEET)
		SpriteHelper.set_cell(sprite, 1, 6, Vector2(-16, -16), Vector2(0.35, 0.35))
		_sprites.append(sprite)


func _process(delta: float) -> void:
	_timer += delta
	if _timer >= DURATION:
		queue_free()
		return
	var t: float = _timer / DURATION
	var radius: float = 4.0 + t * 8.0
	var alpha: float = 1.0 - t
	for i in _sprites.size():
		var angle: float = float(i) / float(_sprites.size()) * TAU
		var offset := Vector2(cos(angle), sin(angle)) * radius
		var sprite := _sprites[i]
		sprite.position = offset + Vector2(-16, -16) * sprite.scale
		sprite.scale = Vector2.ONE * (0.35 * maxf(0.2, 1.0 - t))
		sprite.modulate.a = alpha

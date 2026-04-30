extends Node2D

const SpriteFramesBuilder := preload("res://scripts/visuals/sprite_frames_builder.gd")
const SHEET := preload("res://sprites/effects_sheet.png")
const ANIMATIONS := {
	&"default": {"frames": [4], "fps": 1.0, "loop": false},
}

var _effects: Resource
var _trail_positions: Array[Vector2] = []
var _trail_alphas: Array[float] = []
var _sprites: Array[AnimatedSprite2D] = []
var _distance_accum: float = 0.0
var _last_pos: Vector2 = Vector2.ZERO
const MAX_TRAIL := 5
const MIN_SPEED := 180.0


func _ready() -> void:
	_effects = (owner as CharacterBody2D).effects if owner else preload("res://resources/config/effects_default.tres")
	for i in MAX_TRAIL:
		var sprite := SpriteFramesBuilder.ensure_sprite(self, StringName("Trail%d" % i), SHEET, 6, ANIMATIONS)
		sprite.position = Vector2(-16, -24)
		sprite.scale = Vector2(0.5, 0.7)
		sprite.visible = false
		_sprites.append(sprite)


func _process(delta: float) -> void:
	var body := get_parent() as CharacterBody2D
	if not body or not _effects:
		return

	var speed := absf(body.velocity.x)
	if speed < MIN_SPEED:
		_trail_positions.clear()
		_trail_alphas.clear()
		_distance_accum = 0.0
		_last_pos = body.global_position
		_update_sprites(body)
		return

	var moved := body.global_position.distance_to(_last_pos)
	_distance_accum += moved
	_last_pos = body.global_position

	if _distance_accum >= _effects.motion_trail_spacing:
		_distance_accum = 0.0
		_trail_positions.push_front(body.global_position)
		_trail_alphas.push_front(0.3)
		if _trail_positions.size() > MAX_TRAIL:
			_trail_positions.pop_back()
			_trail_alphas.pop_back()

	for i in _trail_alphas.size():
		_trail_alphas[i] -= delta * 2.0

	while _trail_alphas.size() > 0 and _trail_alphas.back() <= 0.0:
		_trail_alphas.pop_back()
		_trail_positions.pop_back()

	_update_sprites(body)


func _update_sprites(body: CharacterBody2D) -> void:
	for i in _sprites.size():
		var sprite := _sprites[i]
		if i >= _trail_positions.size():
			sprite.visible = false
			continue
		var pos: Vector2 = _trail_positions[i] - body.global_position
		sprite.visible = true
		sprite.position = pos + Vector2(-16, -24) * sprite.scale
		sprite.modulate = Color(1.0, 0.3, 0.3, maxf(_trail_alphas[i], 0.0))

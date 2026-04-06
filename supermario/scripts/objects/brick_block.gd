extends StaticBody2D

const P := preload("res://scripts/color_palette.gd")

@export var coin_count: int = 0
@export var bump_config: Resource  # BlockBumpConfig

var _bumping: bool = false
var _bump_time: float = 0.0
var _bump_offset: float = 0.0
var _used: bool = false


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0


func _process(delta: float) -> void:
	if _bumping:
		_bump_time += delta
		var t: float = _bump_time / bump_config.bump_duration
		if t >= 1.0:
			_bump_offset = 0.0
			_bumping = false
		else:
			_bump_offset = -bump_config.bump_amplitude * sin(t * PI)
		queue_redraw()


func _draw() -> void:
	var y_off: float = _bump_offset
	if _used:
		draw_rect(Rect2(-8, -16 + y_off, 16, 16), P.BLOCK_BROWN)
		draw_rect(Rect2(-8, -16 + y_off, 16, 2), P.BLOCK_BROWN.darkened(0.3))
		draw_rect(Rect2(-8, -2 + y_off, 16, 2), P.BLOCK_BROWN.darkened(0.3))
		draw_rect(Rect2(-8, -16 + y_off, 2, 16), P.BLOCK_BROWN.darkened(0.3))
		draw_rect(Rect2(6, -16 + y_off, 2, 16), P.BLOCK_BROWN.darkened(0.3))
	else:
		draw_rect(Rect2(-8, -16 + y_off, 16, 16), P.BRICK_RED)
		draw_line(Vector2(-8, -8 + y_off), Vector2(8, -8 + y_off), P.BRICK_DARK, 1.0)
		draw_line(Vector2(-8, 0 + y_off), Vector2(8, 0 + y_off), P.BRICK_DARK, 1.0)
		draw_line(Vector2(-4, -16 + y_off), Vector2(-4, -8 + y_off), P.BRICK_DARK, 1.0)
		draw_line(Vector2(4, -16 + y_off), Vector2(4, -8 + y_off), P.BRICK_DARK, 1.0)
		draw_line(Vector2(0, -8 + y_off), Vector2(0, 0 + y_off), P.BRICK_DARK, 1.0)
		draw_line(Vector2(-4, 0 + y_off), Vector2(-4, -1 + y_off), P.BRICK_DARK, 1.0)
		draw_line(Vector2(4, 0 + y_off), Vector2(4, -1 + y_off), P.BRICK_DARK, 1.0)
		draw_rect(Rect2(-8, -16 + y_off, 16, 16), P.BRICK_DARK, false, 1.0)


func bump_from_below() -> void:
	if _used:
		return
	var is_big: bool = GameManager.current_power_state != GameManager.PowerState.SMALL

	if coin_count > 0:
		_bumping = true
		_bump_time = 0.0
		coin_count -= 1
		GameManager.add_coin(global_position + Vector2(0, -16))
		EventBus.block_bumped.emit(global_position)
		if coin_count == 0:
			_used = true
		return

	if is_big:
		EventBus.block_broken.emit(global_position)
		GameManager.add_score(50, global_position)
		queue_free()
	else:
		_bumping = true
		_bump_time = 0.0
		EventBus.block_bumped.emit(global_position)

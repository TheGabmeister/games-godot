extends "res://scripts/objects/block_base.gd"

@export var coin_count: int = 0
@export var break_sound: AudioStream
@export var coin_sound: AudioStream

var _used: bool = false


func _draw() -> void:
	var y_off: float = _bump_offset
	if _used:
		draw_rect(Rect2(-8, -16 + y_off, 16, 16), Palette.BLOCK_BROWN)
		draw_rect(Rect2(-8, -16 + y_off, 16, 2), Palette.BLOCK_BROWN.darkened(0.3))
		draw_rect(Rect2(-8, -2 + y_off, 16, 2), Palette.BLOCK_BROWN.darkened(0.3))
		draw_rect(Rect2(-8, -16 + y_off, 2, 16), Palette.BLOCK_BROWN.darkened(0.3))
		draw_rect(Rect2(6, -16 + y_off, 2, 16), Palette.BLOCK_BROWN.darkened(0.3))
	else:
		draw_rect(Rect2(-8, -16 + y_off, 16, 16), Palette.BRICK_RED)
		draw_line(Vector2(-8, -8 + y_off), Vector2(8, -8 + y_off), Palette.BRICK_DARK, 1.0)
		draw_line(Vector2(-8, 0 + y_off), Vector2(8, 0 + y_off), Palette.BRICK_DARK, 1.0)
		draw_line(Vector2(-4, -16 + y_off), Vector2(-4, -8 + y_off), Palette.BRICK_DARK, 1.0)
		draw_line(Vector2(4, -16 + y_off), Vector2(4, -8 + y_off), Palette.BRICK_DARK, 1.0)
		draw_line(Vector2(0, -8 + y_off), Vector2(0, 0 + y_off), Palette.BRICK_DARK, 1.0)
		draw_line(Vector2(-4, 0 + y_off), Vector2(-4, -1 + y_off), Palette.BRICK_DARK, 1.0)
		draw_line(Vector2(4, 0 + y_off), Vector2(4, -1 + y_off), Palette.BRICK_DARK, 1.0)
		draw_rect(Rect2(-8, -16 + y_off, 16, 16), Palette.BRICK_DARK, false, 1.0)


func bump_from_below() -> void:
	if _used:
		return
	var is_big: bool = GameManager.current_power_state != GameManager.PowerState.SMALL

	if coin_count > 0:
		start_bump()
		coin_count -= 1
		_play_sound(coin_sound)
		GameManager.add_coin(global_position + Vector2(0, -16))
		play_bump_sound()
		EventBus.block_bumped.emit(global_position)
		if coin_count == 0:
			_used = true
		return

	if is_big:
		_play_sound(break_sound)
		EventBus.block_broken.emit(global_position)
		GameManager.add_score(50, global_position)
		queue_free()
	else:
		start_bump()
		play_bump_sound()
		EventBus.block_bumped.emit(global_position)

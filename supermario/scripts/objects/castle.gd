extends Node2D

const CASTLE_COLOR := Color(0.55, 0.35, 0.15)
const CASTLE_DARK := Color(0.40, 0.25, 0.10)


func _draw() -> void:
	# Main body (4 tiles wide, 3 tiles tall)
	draw_rect(Rect2(-32, -48, 64, 48), CASTLE_COLOR)
	# Top crenellations
	for i in 4:
		draw_rect(Rect2(-32 + i * 18, -56, 10, 8), CASTLE_COLOR)
	# Door
	draw_rect(Rect2(-8, -20, 16, 20), Color.BLACK)
	draw_rect(Rect2(-8, -20, 16, 4), CASTLE_DARK)
	# Window
	draw_rect(Rect2(-4, -40, 8, 8), Color.BLACK)
	# Brick lines
	for row in 3:
		var y: float = -48.0 + row * 16.0
		draw_line(Vector2(-32, y), Vector2(32, y), CASTLE_DARK, 1.0)
	for col in 4:
		var x: float = -32.0 + col * 16.0
		draw_line(Vector2(x, -48), Vector2(x, 0), CASTLE_DARK, 1.0)

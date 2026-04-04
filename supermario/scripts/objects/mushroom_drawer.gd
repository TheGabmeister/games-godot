extends Node2D

const P := preload("res://scripts/color_palette.gd")


func _draw() -> void:
	# Origin at bottom center, 16x16 footprint
	# Stem
	draw_rect(Rect2(-4, -6, 8, 6), P.MUSHROOM_CREAM)
	# Cap (dome): draw as rectangle with rounded corners via polygon
	var points := PackedVector2Array()
	var segments := 12
	for i in segments + 1:
		var angle: float = PI - PI * float(i) / float(segments)
		points.append(Vector2(cos(angle) * 8.0, -6.0 + sin(angle) * -8.0))
	draw_colored_polygon(points, P.MUSHROOM_RED)
	# White spots
	draw_circle(Vector2(-3.5, -10), 1.8, P.MUSHROOM_CREAM)
	draw_circle(Vector2(3.5, -10), 1.8, P.MUSHROOM_CREAM)
	draw_circle(Vector2(0, -13), 1.5, P.MUSHROOM_CREAM)

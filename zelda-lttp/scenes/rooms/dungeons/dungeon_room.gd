extends Room
## Base script for dungeon rooms. Draws stone floor with torch lighting.


func _draw() -> void:
	# Dark stone floor
	draw_rect(Rect2(0, 0, 256, 224), Color(0.18, 0.16, 0.2))

	# Tile grid
	var tile_color := Color(0.22, 0.2, 0.24)
	for ty in 14:
		for tx in 16:
			if (tx + ty) % 2 == 0:
				draw_rect(Rect2(tx * 16, ty * 16, 16, 16), tile_color)

	# Wall borders
	var wall_color := Color(0.3, 0.28, 0.32)
	draw_rect(Rect2(0, 0, 256, 16), wall_color)
	draw_rect(Rect2(0, 208, 256, 16), wall_color)
	draw_rect(Rect2(0, 0, 16, 224), wall_color)
	draw_rect(Rect2(240, 0, 16, 224), wall_color)

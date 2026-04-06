extends Room
## Base script for dark world overworld rooms. Darker, twisted versions of light world.


func _draw() -> void:
	# Dead ground
	draw_rect(Rect2(0, 0, 256, 224), Color(0.3, 0.22, 0.28))

	# Seeded variation
	var seed_val := 0
	if room_data:
		seed_val = room_data.screen_coords.x * 73 + room_data.screen_coords.y * 137 + 999
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val

	# Dead tile variation
	var dark_accent := Color(0.25, 0.18, 0.24)
	var dead_detail := Color(0.35, 0.25, 0.3)
	for ty in 14:
		for tx in 16:
			var r := rng.randf()
			if r < 0.2:
				draw_rect(Rect2(tx * 16, ty * 16, 16, 16), dark_accent)
			elif r < 0.28:
				var cx := tx * 16.0 + 8.0
				var cy := ty * 16.0 + 8.0
				draw_circle(Vector2(cx, cy), 1.5, dead_detail)

	# Dead trees / twisted objects
	var tree_color := Color(0.2, 0.12, 0.15)
	for i in rng.randi_range(2, 6):
		var tx := rng.randf_range(16, 240)
		var ty := rng.randf_range(16, 208)
		# Twisted trunk
		draw_rect(Rect2(tx - 2, ty - 2, 4, 8), tree_color)
		# Dead branches
		draw_line(Vector2(tx, ty - 2), Vector2(tx - 5, ty - 7), tree_color, 1.5)
		draw_line(Vector2(tx, ty - 2), Vector2(tx + 4, ty - 8), tree_color, 1.5)

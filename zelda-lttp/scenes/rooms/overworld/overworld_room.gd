extends Room
## Base script for overworld rooms. Draws a tiled floor with biome coloring.
## Each overworld room is 256x224 (16x14 tiles of 16px).

@export var biome: StringName = &"plains"  # plains, forest, mountain, lake

# Biome color palettes
const BIOME_COLORS := {
	&"plains": {
		"ground": Color(0.45, 0.7, 0.35),
		"accent": Color(0.35, 0.6, 0.25),
		"detail": Color(0.55, 0.75, 0.4),
	},
	&"forest": {
		"ground": Color(0.2, 0.45, 0.2),
		"accent": Color(0.15, 0.35, 0.15),
		"detail": Color(0.3, 0.5, 0.25),
	},
	&"mountain": {
		"ground": Color(0.5, 0.45, 0.4),
		"accent": Color(0.4, 0.35, 0.3),
		"detail": Color(0.6, 0.55, 0.45),
	},
	&"lake": {
		"ground": Color(0.35, 0.6, 0.3),
		"accent": Color(0.2, 0.35, 0.65),
		"detail": Color(0.4, 0.65, 0.35),
	},
}


func _draw() -> void:
	var colors: Dictionary = BIOME_COLORS.get(biome, BIOME_COLORS[&"plains"])
	var ground_color: Color = colors["ground"]
	var accent_color: Color = colors["accent"]
	var detail_color: Color = colors["detail"]

	# Draw base ground
	draw_rect(Rect2(0, 0, 256, 224), ground_color)

	# Seeded random for consistent tile variation per room
	var seed_val := 0
	if room_data:
		seed_val = room_data.screen_coords.x * 73 + room_data.screen_coords.y * 137
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val

	# Draw tile variation
	for ty in 14:
		for tx in 16:
			var r := rng.randf()
			if r < 0.15:
				# Accent tile
				draw_rect(Rect2(tx * 16, ty * 16, 16, 16), accent_color)
			elif r < 0.25:
				# Detail dot (grass tuft, pebble, etc.)
				var cx := tx * 16.0 + 8.0
				var cy := ty * 16.0 + 8.0
				draw_circle(Vector2(cx, cy), 1.5, detail_color)

	# Draw biome-specific decorations
	match biome:
		&"forest":
			_draw_trees(rng)
		&"mountain":
			_draw_rocks(rng)
		&"lake":
			_draw_water_patches(rng)


func _draw_trees(rng: RandomNumberGenerator) -> void:
	var tree_color := Color(0.1, 0.3, 0.1)
	var trunk_color := Color(0.35, 0.25, 0.15)
	for i in rng.randi_range(3, 8):
		var tx := rng.randf_range(16, 240)
		var ty := rng.randf_range(16, 208)
		# Trunk
		draw_rect(Rect2(tx - 2, ty, 4, 6), trunk_color)
		# Canopy (circle)
		draw_circle(Vector2(tx, ty - 2), 6.0, tree_color)


func _draw_rocks(rng: RandomNumberGenerator) -> void:
	var rock_color := Color(0.55, 0.5, 0.45)
	for i in rng.randi_range(4, 10):
		var rx := rng.randf_range(8, 248)
		var ry := rng.randf_range(8, 216)
		var size := rng.randf_range(3, 7)
		draw_circle(Vector2(rx, ry), size, rock_color)
		draw_arc(Vector2(rx, ry), size, 0.0, TAU, 12, rock_color.darkened(0.2), 1.0)


func _draw_water_patches(rng: RandomNumberGenerator) -> void:
	var water_color := Color(0.2, 0.35, 0.7, 0.7)
	for i in rng.randi_range(2, 5):
		var wx := rng.randf_range(32, 224)
		var wy := rng.randf_range(32, 192)
		var w := rng.randf_range(16, 48)
		var h := rng.randf_range(16, 32)
		draw_rect(Rect2(wx - w / 2, wy - h / 2, w, h), water_color)

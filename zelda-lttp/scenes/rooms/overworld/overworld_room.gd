extends Room
## Base script for overworld rooms. Draws a tiled floor with biome coloring.
## Each overworld room is 256x224 (16x14 tiles of 16px).

@export var biome: StringName = &"plains"  # plains, forest, mountain, lake, desert, village, graveyard, field

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
	&"desert": {
		"ground": Color(0.75, 0.65, 0.4),
		"accent": Color(0.65, 0.55, 0.3),
		"detail": Color(0.85, 0.75, 0.5),
	},
	&"village": {
		"ground": Color(0.5, 0.65, 0.35),
		"accent": Color(0.55, 0.45, 0.3),
		"detail": Color(0.6, 0.5, 0.35),
	},
	&"graveyard": {
		"ground": Color(0.3, 0.3, 0.25),
		"accent": Color(0.25, 0.25, 0.2),
		"detail": Color(0.4, 0.35, 0.3),
	},
	&"field": {
		"ground": Color(0.5, 0.72, 0.38),
		"accent": Color(0.42, 0.62, 0.3),
		"detail": Color(0.58, 0.78, 0.45),
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
		&"desert":
			_draw_cacti(rng)
		&"village":
			_draw_houses(rng)
		&"graveyard":
			_draw_tombstones(rng)
		&"field":
			_draw_flowers(rng)


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


func _draw_cacti(rng: RandomNumberGenerator) -> void:
	var cactus_color := Color(0.3, 0.55, 0.25)
	var sand_rock := Color(0.6, 0.5, 0.35)
	for i in rng.randi_range(2, 6):
		var cx := rng.randf_range(20, 236)
		var cy := rng.randf_range(20, 204)
		# Trunk
		draw_rect(Rect2(cx - 2, cy - 6, 4, 12), cactus_color)
		# Arms
		draw_rect(Rect2(cx - 6, cy - 4, 4, 3), cactus_color)
		draw_rect(Rect2(cx + 2, cy - 2, 4, 3), cactus_color)
	# Scattered sand rocks
	for i in rng.randi_range(3, 7):
		var rx := rng.randf_range(8, 248)
		var ry := rng.randf_range(8, 216)
		draw_circle(Vector2(rx, ry), rng.randf_range(2, 4), sand_rock)


func _draw_houses(rng: RandomNumberGenerator) -> void:
	var wall_color := Color(0.6, 0.55, 0.45)
	var roof_color := Color(0.5, 0.25, 0.15)
	for i in rng.randi_range(1, 3):
		var hx := rng.randf_range(32, 208)
		var hy := rng.randf_range(32, 176)
		# Walls
		draw_rect(Rect2(hx - 10, hy - 6, 20, 16), wall_color)
		draw_rect(Rect2(hx - 10, hy - 6, 20, 16), wall_color.darkened(0.15), false, 1.0)
		# Roof
		draw_colored_polygon(PackedVector2Array([
			Vector2(hx - 12, hy - 6), Vector2(hx + 12, hy - 6), Vector2(hx, hy - 14),
		]), roof_color)
		# Door
		draw_rect(Rect2(hx - 2, hy + 4, 4, 6), Color(0.3, 0.2, 0.12))
	# Paths between houses
	var path_color := Color(0.55, 0.48, 0.35)
	for i in rng.randi_range(2, 4):
		var px := rng.randf_range(24, 232)
		var py := rng.randf_range(24, 200)
		draw_rect(Rect2(px, py, rng.randf_range(8, 24), 3), path_color)


func _draw_tombstones(rng: RandomNumberGenerator) -> void:
	var stone_color := Color(0.45, 0.42, 0.4)
	var dark_stone := Color(0.35, 0.32, 0.3)
	for i in rng.randi_range(4, 10):
		var tx := rng.randf_range(20, 236)
		var ty := rng.randf_range(20, 204)
		# Base
		draw_rect(Rect2(tx - 4, ty, 8, 3), dark_stone)
		# Stone
		draw_rect(Rect2(tx - 3, ty - 8, 6, 9), stone_color)
		# Rounded top
		draw_circle(Vector2(tx, ty - 8), 3.0, stone_color)
		# Cross etching
		draw_line(Vector2(tx, ty - 7), Vector2(tx, ty - 3), dark_stone, 0.5)
		draw_line(Vector2(tx - 1.5, ty - 5), Vector2(tx + 1.5, ty - 5), dark_stone, 0.5)
	# Dead grass patches
	for i in rng.randi_range(3, 6):
		var gx := rng.randf_range(8, 248)
		var gy := rng.randf_range(8, 216)
		draw_circle(Vector2(gx, gy), 2.0, Color(0.35, 0.32, 0.22))


func _draw_flowers(rng: RandomNumberGenerator) -> void:
	var flower_colors := [Color(0.9, 0.3, 0.3), Color(0.9, 0.8, 0.2), Color(0.4, 0.4, 0.9), Color(0.9, 0.5, 0.8)]
	for i in rng.randi_range(5, 12):
		var fx := rng.randf_range(8, 248)
		var fy := rng.randf_range(8, 216)
		var color: Color = flower_colors[rng.randi() % flower_colors.size()]
		draw_circle(Vector2(fx, fy), 1.5, color)
		draw_circle(Vector2(fx, fy), 0.8, Color(1, 1, 0.6))

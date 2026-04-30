extends Node

## Builds a programmatic TileSet for level terrain.
## Two-tile atlas: tile 0 is the top (with stripe), tile 1 is the fill.
## All visual variation between levels comes from the two color args.

const TILE_SIZE := 32
const TOP_STRIPE_HEIGHT := 6


static func create_tileset(top_color: Color, fill_color: Color) -> TileSet:
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)

	# Atlas image: 2 tiles wide (top, fill), 1 tile tall
	var img := Image.create(TILE_SIZE * 2, TILE_SIZE, false, Image.FORMAT_RGBA8)

	# Tile 0 (0,0): top with stripe
	for y in TILE_SIZE:
		for x in TILE_SIZE:
			if y < TOP_STRIPE_HEIGHT:
				img.set_pixel(x, y, top_color)
			else:
				img.set_pixel(x, y, fill_color)

	# Tile 1 (1,0): solid fill
	for y in TILE_SIZE:
		for x in range(TILE_SIZE, TILE_SIZE * 2):
			img.set_pixel(x, y, fill_color)

	var texture := ImageTexture.create_from_image(img)

	var source := TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	source.create_tile(Vector2i(0, 0))
	source.create_tile(Vector2i(1, 0))

	tileset.add_source(source, 0)

	# Physics layer 1: Terrain
	tileset.add_physics_layer()
	tileset.set_physics_layer_collision_layer(0, 1)
	tileset.set_physics_layer_collision_mask(0, 0)

	@warning_ignore("integer_division")
	var half: int = TILE_SIZE / 2
	var polygon := PackedVector2Array([
		Vector2(-half, -half), Vector2(TILE_SIZE - half, -half),
		Vector2(TILE_SIZE - half, TILE_SIZE - half), Vector2(-half, TILE_SIZE - half),
	])

	for tile_coord in [Vector2i(0, 0), Vector2i(1, 0)]:
		var tile_data := source.get_tile_data(tile_coord, 0)
		tile_data.add_collision_polygon(0)
		tile_data.set_collision_polygon_points(0, 0, polygon)

	return tileset

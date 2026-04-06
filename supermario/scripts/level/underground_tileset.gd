extends Node

## Creates a programmatic TileSet with underground-themed tiles.
## Tile 0: ceiling/floor top (blue-gray with dark top stripe)
## Tile 1: fill (solid blue-gray)

const TILE_SIZE := 16

static func create_tileset() -> TileSet:
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)

	var img := Image.create(TILE_SIZE * 2, TILE_SIZE, false, Image.FORMAT_RGBA8)

	var base := Color(0.30, 0.30, 0.42)
	var dark := Color(0.18, 0.18, 0.28)

	# Tile 0 (0,0): floor/ceiling top with dark stripe
	for y in TILE_SIZE:
		for x in TILE_SIZE:
			if y < 3:
				img.set_pixel(x, y, dark)
			else:
				img.set_pixel(x, y, base)

	# Tile 1 (1,0): solid fill
	for y in TILE_SIZE:
		for x in range(TILE_SIZE, TILE_SIZE * 2):
			img.set_pixel(x, y, base)

	var texture := ImageTexture.create_from_image(img)

	var source := TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	source.create_tile(Vector2i(0, 0))
	source.create_tile(Vector2i(1, 0))

	tileset.add_source(source, 0)

	tileset.add_physics_layer()
	tileset.set_physics_layer_collision_layer(0, 1)
	tileset.set_physics_layer_collision_mask(0, 0)

	for tile_coord in [Vector2i(0, 0), Vector2i(1, 0)]:
		var tile_data := source.get_tile_data(tile_coord, 0)
		var polygon := PackedVector2Array([
			Vector2(0, 0), Vector2(TILE_SIZE, 0),
			Vector2(TILE_SIZE, TILE_SIZE), Vector2(0, TILE_SIZE),
		])
		tile_data.add_collision_polygon(0)
		tile_data.set_collision_polygon_points(0, 0, polygon)

	return tileset

extends Node

## Creates a programmatic TileSet with solid-color tiles for terrain.
## Call create_tileset() to get a TileSet ready for a TileMapLayer.

const TILE_SIZE := 16

static func create_tileset() -> TileSet:
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)

	# Create an atlas image: 2 tiles wide (ground_top, ground_fill), 1 tile tall
	var img := Image.create(TILE_SIZE * 2, TILE_SIZE, false, Image.FORMAT_RGBA8)

	# Tile 0 (0,0): ground_top - brown with green top stripe
	var brown := Color(0.55, 0.35, 0.15)
	var green := Color(0.25, 0.65, 0.25)
	for y in TILE_SIZE:
		for x in TILE_SIZE:
			if y < 3:
				img.set_pixel(x, y, green)
			else:
				img.set_pixel(x, y, brown)

	# Tile 1 (1,0): ground_fill - solid brown
	for y in TILE_SIZE:
		for x in range(TILE_SIZE, TILE_SIZE * 2):
			img.set_pixel(x, y, brown)

	var texture := ImageTexture.create_from_image(img)

	var source := TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	source.create_tile(Vector2i(0, 0))  # ground_top
	source.create_tile(Vector2i(1, 0))  # ground_fill

	tileset.add_source(source, 0)

	# Add physics layer for terrain collision (layer 1)
	tileset.add_physics_layer()
	tileset.set_physics_layer_collision_layer(0, 1)  # Layer 1: Terrain
	tileset.set_physics_layer_collision_mask(0, 0)

	# Set collision polygons for both tiles
	for tile_coord in [Vector2i(0, 0), Vector2i(1, 0)]:
		var tile_data := source.get_tile_data(tile_coord, 0)
		var polygon := PackedVector2Array([
			Vector2(0, 0), Vector2(TILE_SIZE, 0),
			Vector2(TILE_SIZE, TILE_SIZE), Vector2(0, TILE_SIZE),
		])
		tile_data.add_collision_polygon(0)
		tile_data.set_collision_polygon_points(0, 0, polygon)

	return tileset

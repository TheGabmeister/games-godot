extends Node

## Builds a TileSet from the generated terrain sprite sheet.

const TERRAIN_SHEET := preload("res://sprites/terrain_sheet.png")
const TILE_SIZE := 32


static func create_tileset(_top_color: Color, _fill_color: Color) -> TileSet:
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)

	var source := TileSetAtlasSource.new()
	source.texture = TERRAIN_SHEET
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	for x in 4:
		source.create_tile(Vector2i(x, 0))

	tileset.add_source(source, 0)

	tileset.add_physics_layer()
	tileset.set_physics_layer_collision_layer(0, 1)
	tileset.set_physics_layer_collision_mask(0, 0)

	@warning_ignore("integer_division")
	var half: int = TILE_SIZE / 2
	var polygon := PackedVector2Array([
		Vector2(-half, -half), Vector2(TILE_SIZE - half, -half),
		Vector2(TILE_SIZE - half, TILE_SIZE - half), Vector2(-half, TILE_SIZE - half),
	])

	for tile_coord in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]:
		var tile_data := source.get_tile_data(tile_coord, 0)
		tile_data.add_collision_polygon(0)
		tile_data.set_collision_polygon_points(0, 0, polygon)

	return tileset

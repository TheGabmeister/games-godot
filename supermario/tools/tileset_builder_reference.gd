## Original tileset_builder.gd — deleted 2026-05-01
##
## This script built the TileSet programmatically from terrain_sheet.png.
## Its output was baked to resources/tilesets/terrain_tileset.tres and the
## tile data was embedded in the level .tscn files. Kept here as reference
## for how the TileSet was constructed.
##
## Tile layout in terrain_sheet.png (128x32, 4 tiles):
##   (0,0): Overworld top (green/brown grass)
##   (1,0): Overworld fill (solid brown)
##   (2,0): Underground top (dark gray-blue)
##   (3,0): Underground fill (light gray-blue)
##
## Physics: All 4 tiles have full-tile (32x32) collision polygons on
## physics layer 0 (collision_layer=1, collision_mask=0). Polygon coords
## are relative to tile center per Godot 4 convention.

extends Node

const TERRAIN_SHEET := preload("res://sprites/terrain_sheet.png")
const TILE_SIZE := 32


static func create_tileset() -> TileSet:
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

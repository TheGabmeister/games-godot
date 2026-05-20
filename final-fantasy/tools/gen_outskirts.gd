@tool
extends SceneTree

func _init() -> void:
	var tileset: TileSet = load("res://tilesets/cornelia_tileset.tres")
	var tilemap := TileMapLayer.new()
	tilemap.tile_set = tileset

	# 20x12 grid
	for y in range(12):
		for x in range(20):
			var atlas := Vector2i(0, 0)  # grass
			if 9 <= x and x <= 10 and y <= 10:
				atlas = Vector2i(1, 0)  # path
			if y == 0 or y == 11 or x == 0 or x == 19:
				atlas = Vector2i(5, 0)  # trees
			tilemap.set_cell(Vector2i(x, y), 0, atlas)

	var scene := PackedScene.new()
	var root := Node2D.new()
	root.name = "CorneliaTileMap"
	root.add_child(tilemap)
	tilemap.name = "TileMapLayer"
	tilemap.owner = root

	var err := scene.pack(root)
	if err == OK:
		ResourceSaver.save(scene, "res://tools/outskirts_tilemap.tscn")
		print("Saved outskirts tilemap")
	else:
		print("Error packing scene: ", err)

	quit()

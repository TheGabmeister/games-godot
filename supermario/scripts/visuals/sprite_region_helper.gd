extends RefCounted

const CELL_SIZE := 32


static func ensure_sprite(parent: Node, node_name: StringName, texture: Texture2D) -> Sprite2D:
	var sprite := parent.get_node_or_null(NodePath(node_name)) as Sprite2D
	if sprite == null:
		sprite = Sprite2D.new()
		sprite.name = node_name
		parent.add_child(sprite)
	sprite.texture = texture
	sprite.region_enabled = true
	sprite.centered = false
	return sprite


static func set_cell(sprite: Sprite2D, frame: int, columns: int, position: Vector2, scale: Vector2 = Vector2.ONE) -> void:
	var col := frame % columns
	@warning_ignore("integer_division")
	var row := frame / columns
	sprite.region_rect = Rect2(col * CELL_SIZE, row * CELL_SIZE, CELL_SIZE, CELL_SIZE)
	sprite.position = position
	sprite.scale = scale

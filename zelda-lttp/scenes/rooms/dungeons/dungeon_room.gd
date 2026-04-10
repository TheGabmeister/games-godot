extends Room
## Base script for dungeon rooms. Draws stone floor with torch lighting.


func _ready() -> void:
	if room_data and room_data.is_dark_room:
		var cm: CanvasModulate = get_node_or_null("CanvasModulate")
		if cm:
			var lit_flag := "%s/lit" % room_data.room_id
			if not GameManager.get_flag(lit_flag):
				cm.color = Color(0.05, 0.05, 0.08)
	EventBus.room_lit.connect(_on_room_lit)


func _on_room_lit(lit_room_id: StringName) -> void:
	if room_data and lit_room_id == room_data.room_id:
		var cm: CanvasModulate = get_node_or_null("CanvasModulate")
		if cm:
			var tween := create_tween()
			tween.tween_property(cm, "color", room_data.ambient_color, 0.5)
			GameManager.set_flag("%s/lit" % room_data.room_id, true)


func _draw() -> void:
	# Dark stone floor
	draw_rect(Rect2(0, 0, 256, 224), Color(0.18, 0.16, 0.2))

	# Tile grid
	var tile_color := Color(0.22, 0.2, 0.24)
	for ty in 14:
		for tx in 16:
			if (tx + ty) % 2 == 0:
				draw_rect(Rect2(tx * 16, ty * 16, 16, 16), tile_color)

	# Wall borders
	var wall_color := Color(0.3, 0.28, 0.32)
	draw_rect(Rect2(0, 0, 256, 16), wall_color)
	draw_rect(Rect2(0, 208, 256, 16), wall_color)
	draw_rect(Rect2(0, 0, 16, 224), wall_color)
	draw_rect(Rect2(240, 0, 16, 224), wall_color)

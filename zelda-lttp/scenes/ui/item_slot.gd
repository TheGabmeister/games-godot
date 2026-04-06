extends Control

const SLOT_SIZE := 16.0


func _ready() -> void:
	custom_minimum_size = Vector2(SLOT_SIZE + 4, SLOT_SIZE + 4)
	queue_redraw()


func _draw() -> void:
	# Box outline for equipped item slot
	var rect := Rect2(Vector2(2, 2), Vector2(SLOT_SIZE, SLOT_SIZE))
	draw_rect(rect, Color(0.8, 0.8, 0.8, 0.6), false, 1.0)

	# Draw equipped item icon if available
	var skill: ItemData = PlayerState.get_equipped_skill()
	if skill and skill.icon_shape.size() > 0:
		var offset := Vector2(2 + SLOT_SIZE / 2.0, 2 + SLOT_SIZE / 2.0)
		var points := PackedVector2Array()
		for p in skill.icon_shape:
			points.append(p + offset)
		draw_colored_polygon(points, skill.icon_color)

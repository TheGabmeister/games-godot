class_name PitHazard extends Area2D
## Reusable pit hazard that triggers Fall state on the player.


func _ready() -> void:
	collision_layer = 64  # Hazards
	collision_mask = 2    # Player
	monitoring = true
	monitorable = true

	# Set damage meta for HurtboxComponent detection
	set_meta("damage", 2)
	set_meta("damage_type", 5)  # PIT
	set_meta("source_position", global_position)

	if not _has_shape():
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(14, 14)
		shape.shape = rect
		add_child(shape)

	queue_redraw()


func _has_shape() -> bool:
	for child in get_children():
		if child is CollisionShape2D:
			return true
	return false


func _draw() -> void:
	# Dark pit hole
	var hw := 7.0
	var hh := 7.0
	for child in get_children():
		if child is CollisionShape2D and child.shape is RectangleShape2D:
			hw = child.shape.size.x * 0.5
			hh = child.shape.size.y * 0.5
			break
	draw_rect(Rect2(-hw, -hh, hw * 2, hh * 2), Color(0.05, 0.03, 0.08))
	draw_rect(Rect2(-hw, -hh, hw * 2, hh * 2), Color(0.1, 0.08, 0.12), false, 1.0)

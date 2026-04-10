class_name SkullRock extends Destructible
## Light grey stone. Requires Power Glove (weight 1) to lift.


func _ready() -> void:
	weight = 1
	liftable = true
	sword_destroyable = false
	dash_destroyable = false

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16, 16)
	shape.shape = rect
	add_child(shape)

	super._ready()


func _get_particle_color() -> Color:
	return Color(0.55, 0.5, 0.45)


func _draw() -> void:
	# Light grey stone with rough edges
	draw_circle(Vector2(0, 0), 7.0, Color(0.55, 0.52, 0.48))
	draw_circle(Vector2(-2, -1), 5.0, Color(0.6, 0.57, 0.52))
	draw_circle(Vector2(2, 1), 4.5, Color(0.5, 0.48, 0.44))
	# Crack detail
	draw_line(Vector2(-3, -2), Vector2(1, 3), Color(0.4, 0.38, 0.35), 0.5)

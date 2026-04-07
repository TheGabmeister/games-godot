class_name DarkBoulder extends Destructible
## Large dark boulder. Requires Titan's Mitt (weight 2) to lift.


func _ready() -> void:
	weight = 2
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
	return Color(0.3, 0.28, 0.25)


func _draw() -> void:
	# Dark boulder — large dark stone
	draw_circle(Vector2(0, 0), 8.0, Color(0.3, 0.28, 0.25))
	draw_circle(Vector2(-1, -1), 6.5, Color(0.35, 0.32, 0.28))
	draw_circle(Vector2(2, 2), 5.0, Color(0.28, 0.25, 0.22))
	# Surface texture lines
	draw_line(Vector2(-4, -3), Vector2(3, 2), Color(0.22, 0.2, 0.18), 0.5)
	draw_line(Vector2(-2, 3), Vector2(4, -1), Color(0.22, 0.2, 0.18), 0.5)

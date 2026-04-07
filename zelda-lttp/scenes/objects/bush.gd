class_name Bush extends Destructible
## Destroyable by sword, dash, or throw. Liftable (weight 0).


func _ready() -> void:
	weight = 0
	liftable = true
	sword_destroyable = true
	dash_destroyable = true

	# Collision shape
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(14, 14)
	shape.shape = rect
	add_child(shape)

	super._ready()


func _get_particle_color() -> Color:
	return Color(0.3, 0.6, 0.2)


func _draw() -> void:
	# Green bush — circle with darker outline
	draw_circle(Vector2.ZERO, 7.0, Color(0.25, 0.55, 0.2))
	draw_circle(Vector2(0, -1), 6.0, Color(0.35, 0.65, 0.25))
	draw_circle(Vector2(-2, 1), 4.0, Color(0.3, 0.6, 0.22))
	draw_circle(Vector2(2, 1), 4.0, Color(0.32, 0.62, 0.24))

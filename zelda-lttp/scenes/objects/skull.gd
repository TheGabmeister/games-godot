class_name Skull extends Destructible
## Liftable (weight 0), throw-destroyable. Can weigh down pressure plates.


func _ready() -> void:
	weight = 0
	liftable = true
	sword_destroyable = false
	dash_destroyable = false

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(12, 12)
	shape.shape = rect
	add_child(shape)

	super._ready()


func _get_particle_color() -> Color:
	return Color(0.7, 0.65, 0.6)


func _draw() -> void:
	# White/gray skull shape
	draw_circle(Vector2(0, -1), 6.0, Color(0.75, 0.7, 0.65))
	# Jaw
	draw_rect(Rect2(-4, 3, 8, 3), Color(0.65, 0.6, 0.55))
	# Eye sockets
	draw_circle(Vector2(-2, -2), 1.5, Color(0.15, 0.12, 0.1))
	draw_circle(Vector2(2, -2), 1.5, Color(0.15, 0.12, 0.1))
	# Nose
	draw_rect(Rect2(-0.5, 0, 1, 2), Color(0.2, 0.18, 0.15))

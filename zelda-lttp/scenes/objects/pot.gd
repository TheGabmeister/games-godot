class_name Pot extends Destructible
## Liftable (weight 0), not sword-destroyable. Shatters on throw.


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
	return Color(0.6, 0.45, 0.3)


func _draw() -> void:
	# Clay pot — brown rounded rectangle with rim
	draw_rect(Rect2(-5, -3, 10, 10), Color(0.55, 0.38, 0.22))
	draw_rect(Rect2(-6, -4, 12, 3), Color(0.6, 0.42, 0.25))
	# Rim
	draw_rect(Rect2(-6, -5, 12, 2), Color(0.65, 0.48, 0.3))
	# Dark interior hint
	draw_rect(Rect2(-4, -4, 8, 1), Color(0.2, 0.15, 0.1))

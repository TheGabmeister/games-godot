class_name SignPost extends Destructible
## Liftable (weight 0). Shows dialog_lines on first interact, lifts on second.

@export var dialog_lines: Array[String] = []

var _dialog_shown: bool = false


func _ready() -> void:
	weight = 0
	liftable = true
	sword_destroyable = false
	dash_destroyable = false

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(14, 14)
	shape.shape = rect
	add_child(shape)

	super._ready()


func interact() -> void:
	if _destroyed:
		return
	if not dialog_lines.is_empty() and not _dialog_shown:
		_dialog_shown = true
		EventBus.dialog_requested.emit(dialog_lines)
		return
	# Second interact (or no dialog): lift
	_dialog_shown = false
	if liftable:
		_try_lift()


func _get_particle_color() -> Color:
	return Color(0.5, 0.35, 0.2)


func _draw() -> void:
	# Sign post — wooden rectangle on a post
	# Post
	draw_rect(Rect2(-1, 2, 2, 6), Color(0.4, 0.28, 0.15))
	# Board
	draw_rect(Rect2(-7, -5, 14, 8), Color(0.55, 0.4, 0.2))
	draw_rect(Rect2(-7, -5, 14, 8), Color(0.65, 0.48, 0.25), false, 1.0)
	# Text lines hint
	draw_line(Vector2(-4, -3), Vector2(4, -3), Color(0.3, 0.2, 0.1), 0.5)
	draw_line(Vector2(-4, -1), Vector2(3, -1), Color(0.3, 0.2, 0.1), 0.5)

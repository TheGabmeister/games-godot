extends Node2D

## Test sign for debug room — triggers dialog on interact.

@export var lines: Array = ["This is a test sign.", "It has multiple pages.", "Dialog system works!"]


func _ready() -> void:
	# Create interaction area
	var area := Area2D.new()
	area.collision_layer = 32  # Interactables
	area.collision_mask = 0
	area.monitorable = true
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(14, 14)
	shape.shape = rect
	area.add_child(shape)
	add_child(area)
	queue_redraw()


func interact() -> void:
	EventBus.dialog_requested.emit(lines)


func _draw() -> void:
	# Simple sign post
	draw_rect(Rect2(-1, -4, 2, 8), Color(0.5, 0.35, 0.2))  # Post
	draw_rect(Rect2(-6, -8, 12, 6), Color(0.6, 0.45, 0.25))  # Board
	draw_rect(Rect2(-6, -8, 12, 6), Color(0.4, 0.3, 0.15), false, 1.0)

extends Control

var _rupees: int = 0
@onready var _label: Label = $Label


func _ready() -> void:
	custom_minimum_size = Vector2(50, 12)
	_rupees = PlayerState.rupees
	queue_redraw()
	if _label:
		_label.text = str(_rupees)


func update_rupees(amount: int) -> void:
	_rupees = amount
	queue_redraw()
	if _label:
		_label.text = str(_rupees)


func _draw() -> void:
	# Green diamond (rupee icon)
	var diamond_center := Vector2(5, 6)
	var s := 4.0
	var points := PackedVector2Array([
		diamond_center + Vector2(0, -s),
		diamond_center + Vector2(s * 0.6, 0),
		diamond_center + Vector2(0, s),
		diamond_center + Vector2(-s * 0.6, 0),
	])
	draw_colored_polygon(points, Color(0.1, 0.8, 0.2))

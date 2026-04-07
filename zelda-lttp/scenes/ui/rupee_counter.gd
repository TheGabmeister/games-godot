extends Control

var _rupees: int = 0
var _display_rupees: int = 0
var _tick_timer: float = 0.0
const TICK_INTERVAL := 0.03  # Time between each digit tick

@onready var _label: Label = $Label


func _ready() -> void:
	custom_minimum_size = Vector2(50, 12)
	_rupees = PlayerState.rupees
	_display_rupees = _rupees
	queue_redraw()
	if _label:
		_label.text = str(_display_rupees)


func _process(delta: float) -> void:
	if _display_rupees == _rupees:
		return
	_tick_timer -= delta
	if _tick_timer <= 0.0:
		_tick_timer = TICK_INTERVAL
		if _display_rupees < _rupees:
			_display_rupees += 1
		elif _display_rupees > _rupees:
			_display_rupees -= 1
		if _label:
			_label.text = str(_display_rupees)


func update_rupees(amount: int) -> void:
	_rupees = amount


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

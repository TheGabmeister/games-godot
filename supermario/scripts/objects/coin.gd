extends Area2D

var _spin_time: float = 0.0
var _collected: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_spin_time += delta
	queue_redraw()


func _draw() -> void:
	if _collected:
		return
	# Faux-3D spin: modulate width with sine
	var scale_x := cos(_spin_time * TAU * 1.5)
	var width := 6.0 * absf(scale_x)
	if width < 0.5:
		width = 0.5
	# Outer coin body
	draw_rect(Rect2(-width, -7, width * 2.0, 14), Palette.COIN_GOLD)
	# Inner shine
	var shine_width := width * 0.5
	draw_rect(Rect2(-shine_width, -5, shine_width * 2.0, 10), Palette.COIN_SHINE)


func _on_body_entered(_body: Node2D) -> void:
	_collect()


func _collect() -> void:
	if _collected:
		return
	_collected = true
	GameManager.add_coin(global_position)
	queue_free()

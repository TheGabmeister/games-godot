extends Control

var _current_health: int = 6
var _max_health: int = 6
var _prev_health: int = 6

# Flash animation: tracks which heart indices are flashing white
var _flash_hearts: Dictionary = {}  # heart_index -> flash_timer (0.0 to 1.0)
const FLASH_DURATION := 0.3

const HEART_SIZE := 9.0
const HEART_SPACING := 10.0
const HEARTS_PER_ROW := 10


func _ready() -> void:
	custom_minimum_size = Vector2(HEARTS_PER_ROW * HEART_SPACING, 20)
	_current_health = PlayerState.current_health
	_max_health = PlayerState.max_health
	_prev_health = _current_health
	queue_redraw()


func _process(delta: float) -> void:
	if _flash_hearts.is_empty():
		return
	var any_active := false
	for idx: int in _flash_hearts.keys():
		_flash_hearts[idx] -= delta / FLASH_DURATION
		if _flash_hearts[idx] <= 0.0:
			_flash_hearts.erase(idx)
		else:
			any_active = true
	if any_active or _flash_hearts.size() > 0:
		queue_redraw()


func update_hearts(current: int, max_health: int) -> void:
	var old_health := _current_health
	_current_health = current
	_max_health = max_health
	# Trigger flash on hearts that lost health
	if current < old_health:
		var old_full := old_health / 2
		var new_full := current / 2
		for i in range(new_full, old_full + 1):
			if i >= 0:
				_flash_hearts[i] = 1.0
	queue_redraw()


func _draw() -> void:
	var total_hearts := _max_health / 2
	for i in total_hearts:
		var x := float(i % HEARTS_PER_ROW) * HEART_SPACING + HEART_SIZE / 2.0
		var y := float(i / HEARTS_PER_ROW) * HEART_SPACING + HEART_SIZE / 2.0
		var center := Vector2(x, y)

		# Check if this heart is flashing
		if _flash_hearts.has(i):
			var t: float = _flash_hearts[i]
			_draw_heart(center, Color(1.0, 1.0, 1.0, 0.5 + 0.5 * t))
			continue

		var half_hearts_for_this := clampi(_current_health - i * 2, 0, 2)
		if half_hearts_for_this == 2:
			_draw_heart(center, Color(0.9, 0.1, 0.1))  # Full
		elif half_hearts_for_this == 1:
			_draw_heart_half(center)  # Half
		else:
			_draw_heart(center, Color(0.25, 0.1, 0.1))  # Empty


func _draw_heart(center: Vector2, color: Color) -> void:
	var s := HEART_SIZE / 2.0
	var points := PackedVector2Array([
		center + Vector2(0, -s * 0.3),
		center + Vector2(s * 0.5, -s * 0.8),
		center + Vector2(s * 0.9, -s * 0.4),
		center + Vector2(s * 0.7, s * 0.1),
		center + Vector2(0, s * 0.8),
		center + Vector2(-s * 0.7, s * 0.1),
		center + Vector2(-s * 0.9, -s * 0.4),
		center + Vector2(-s * 0.5, -s * 0.8),
	])
	draw_colored_polygon(points, color)


func _draw_heart_half(center: Vector2) -> void:
	# Draw empty outline first
	_draw_heart(center, Color(0.25, 0.1, 0.1))
	# Draw left half filled
	var s := HEART_SIZE / 2.0
	var points := PackedVector2Array([
		center + Vector2(0, -s * 0.3),
		center + Vector2(0, s * 0.8),
		center + Vector2(-s * 0.7, s * 0.1),
		center + Vector2(-s * 0.9, -s * 0.4),
		center + Vector2(-s * 0.5, -s * 0.8),
	])
	draw_colored_polygon(points, Color(0.9, 0.1, 0.1))

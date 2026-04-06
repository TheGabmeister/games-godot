extends Area2D

const P := preload("res://scripts/color_palette.gd")

@export var item_config: Resource  # ItemConfig

var _emerge_start_y: float = 0.0
var _emerge_initialized: bool = false
var _emerge_timer: float = 0.0
var _emerging: bool = true
var _collected: bool = false


func _ready() -> void:
	# NOTE: We intentionally do NOT capture _emerge_start_y here. _ready()
	# fires synchronously inside get_parent().add_child(item) in the
	# spawning question block, which runs BEFORE the spawner sets
	# global_position.
	monitoring = false
	body_entered.connect(_on_body_entered)
	queue_redraw()


func _process(delta: float) -> void:
	if _collected:
		return

	if _emerging:
		if not _emerge_initialized:
			_emerge_start_y = global_position.y
			_emerge_initialized = true
		_emerge_timer += delta
		var t: float = minf(_emerge_timer / item_config.emerge_duration, 1.0)
		global_position.y = _emerge_start_y - item_config.emerge_height * t
		if t >= 1.0:
			_emerging = false
			monitoring = true


func _draw() -> void:
	draw_rect(Rect2(-1, -8, 2, 8), P.PIRANHA_GREEN)
	for i in 5:
		var angle: float = (float(i) / 5.0) * TAU - PI * 0.5
		var px: float = cos(angle) * 3.5
		var py: float = -11.0 + sin(angle) * 3.5
		var petal_color: Color = P.FIRE_ORANGE if i % 2 == 0 else P.FIRE_RED
		draw_circle(Vector2(px, py), 3.0, petal_color)
	draw_circle(Vector2(0, -11), 1.8, P.STAR_YELLOW)


func _on_body_entered(body: Node) -> void:
	if _collected:
		return
	if body.has_method("power_up"):
		_collected = true
		body.power_up(&"fire_flower", global_position)
		queue_free()

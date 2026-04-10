extends Area2D

const P := preload("res://scripts/color_palette.gd")
const EmergeHelper := preload("res://scripts/objects/emerge_helper.gd")

@export var item_config: Resource  # ItemConfig

var _emerge := EmergeHelper.new()
var _collected: bool = false


func _ready() -> void:
	# Emerge start position is captured lazily by EmergeHelper on the first
	# tick. _ready() fires synchronously inside the spawning question block's
	# add_child(), BEFORE the spawner sets global_position.
	monitoring = false
	body_entered.connect(_on_body_entered)
	queue_redraw()


func _process(delta: float) -> void:
	if _collected:
		return

	if not _emerge.done:
		global_position.y = _emerge.update(delta, global_position.y, item_config.emerge_duration, item_config.emerge_height)
		if _emerge.done:
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

extends Node2D

## Draws repeating cloud and hill decorations with simple parallax.
## Attach as a child of a CanvasLayer at layer -1.

const P := preload("res://scripts/color_palette.gd")

@export var parallax_clouds: float = 0.3
@export var parallax_hills: float = 0.5

var _camera: Camera2D


func _ready() -> void:
	# Find the player's camera
	var player := get_tree().get_first_node_in_group("player")
	if player:
		_camera = player.get_node("Camera2D") as Camera2D


func _process(_delta: float) -> void:
	if _camera:
		# Shift position based on camera for parallax effect
		queue_redraw()


func _draw() -> void:
	var cam_x: float = 0.0
	if _camera:
		cam_x = _camera.global_position.x

	_draw_hills(cam_x)
	_draw_clouds(cam_x)
	_draw_bushes(cam_x)


func _draw_hills(cam_x: float) -> void:
	var hill_color := P.GROUND_GREEN.lightened(0.2)
	var offset_x := cam_x * (1.0 - parallax_hills)
	# Repeat hills every 768px
	var pattern_width: float = 768.0
	var start_x := floorf((cam_x - 256.0 - offset_x) / pattern_width) * pattern_width
	for i in 3:
		var base_x := start_x + i * pattern_width - offset_x
		# Large hill
		_draw_hill(Vector2(base_x, 192.0), 60.0, 30.0, hill_color)
		# Small hill
		_draw_hill(Vector2(base_x + 250.0, 192.0), 35.0, 18.0, hill_color.lightened(0.1))


func _draw_hill(center: Vector2, radius_x: float, radius_y: float, color: Color) -> void:
	var points := PackedVector2Array()
	var segments := 16
	for i in segments + 1:
		var angle := PI - PI * float(i) / float(segments)
		points.append(Vector2(
			center.x + cos(angle) * radius_x,
			center.y - sin(angle) * radius_y,
		))
	points.append(Vector2(center.x + radius_x, center.y))
	draw_colored_polygon(points, color)


func _draw_clouds(cam_x: float) -> void:
	var offset_x := cam_x * (1.0 - parallax_clouds)
	var pattern_width: float = 512.0
	var start_x := floorf((cam_x - 256.0 - offset_x) / pattern_width) * pattern_width
	for i in 4:
		var base_x := start_x + i * pattern_width - offset_x
		_draw_cloud(Vector2(base_x + 60.0, 40.0), 1.0)
		_draw_cloud(Vector2(base_x + 200.0, 55.0), 0.7)
		_draw_cloud(Vector2(base_x + 380.0, 35.0), 1.2)


func _draw_cloud(center: Vector2, size_scale: float) -> void:
	var color := Color(1.0, 1.0, 1.0, 0.8)
	var r := 12.0 * size_scale
	draw_circle(center, r, color)
	draw_circle(center + Vector2(-r * 0.8, 2.0), r * 0.8, color)
	draw_circle(center + Vector2(r * 0.8, 2.0), r * 0.8, color)


func _draw_bushes(cam_x: float) -> void:
	var bush_color := P.GROUND_GREEN.darkened(0.1)
	var offset_x := cam_x * (1.0 - parallax_hills)
	var pattern_width: float = 768.0
	var start_x := floorf((cam_x - 256.0 - offset_x) / pattern_width) * pattern_width
	for i in 3:
		var base_x := start_x + i * pattern_width - offset_x
		_draw_bush(Vector2(base_x + 130.0, 192.0), 1.0, bush_color)
		_draw_bush(Vector2(base_x + 400.0, 192.0), 0.6, bush_color)


func _draw_bush(center: Vector2, size_scale: float, color: Color) -> void:
	var r := 10.0 * size_scale
	draw_circle(center + Vector2(0, -r * 0.3), r, color)
	draw_circle(center + Vector2(-r, 0), r * 0.7, color)
	draw_circle(center + Vector2(r, 0), r * 0.7, color)

extends Node2D

# Draws the player using primitive shapes:
# Green pentagon torso, skin-tone circle head, directional cap triangle

@onready var player: Player = get_parent()

var _sword_arc_alpha: float = 0.0


func _draw() -> void:
	if not player:
		return

	var facing := player.facing_direction

	# Body: green pentagon (simplified as a rectangle with angled top)
	var body_color := Color(0.2, 0.65, 0.2)
	var body_points := PackedVector2Array([
		Vector2(-5, -2),
		Vector2(5, -2),
		Vector2(6, 6),
		Vector2(-6, 6),
	])
	draw_colored_polygon(body_points, body_color)

	# Head: skin-tone circle
	var head_color := Color(0.95, 0.8, 0.6)
	draw_circle(Vector2(0, -4), 4.0, head_color)

	# Cap triangle: rotates to face direction
	var cap_color := Color(0.15, 0.5, 0.15)
	var cap_dir := facing.normalized() if facing != Vector2.ZERO else Vector2.DOWN
	var cap_center := Vector2(0, -4) + cap_dir * 4.0
	var cap_perp := Vector2(-cap_dir.y, cap_dir.x)
	var cap_tip := cap_center + cap_dir * 4.0
	var cap_left := cap_center + cap_perp * 3.0
	var cap_right := cap_center - cap_perp * 3.0
	draw_colored_polygon(PackedVector2Array([cap_tip, cap_left, cap_right]), cap_color)

	# Sword arc during attack
	if player.sword_active:
		_draw_sword_arc()


func _draw_sword_arc() -> void:
	var facing := player.facing_direction.normalized()
	if facing == Vector2.ZERO:
		facing = Vector2.DOWN

	var sword_color := Color(0.95, 0.95, 0.8, 0.9)
	var sword_length := 10.0
	var arc_angle := player.sword_arc_progress * PI - PI / 2.0

	# Rotate sword around facing direction
	var base_angle := facing.angle()
	var sword_angle := base_angle + arc_angle
	var sword_dir := Vector2.from_angle(sword_angle)
	var sword_start := facing * 4.0
	var sword_end := sword_start + sword_dir * sword_length
	var sword_perp := Vector2(-sword_dir.y, sword_dir.x)

	var sword_points := PackedVector2Array([
		sword_start + sword_perp * 1.5,
		sword_end + sword_perp * 0.5,
		sword_end - sword_perp * 0.5,
		sword_start - sword_perp * 1.5,
	])
	draw_colored_polygon(sword_points, sword_color)

	# Trail copies for arc effect
	for i in range(3):
		var trail_progress := player.sword_arc_progress - (i + 1) * 0.15
		if trail_progress < 0.0:
			continue
		var trail_angle := base_angle + trail_progress * PI - PI / 2.0
		var trail_dir := Vector2.from_angle(trail_angle)
		var trail_end := sword_start + trail_dir * sword_length
		var trail_perp := Vector2(-trail_dir.y, trail_dir.x)
		var alpha := 0.4 - float(i) * 0.12
		var trail_color := Color(0.95, 0.95, 0.8, alpha)
		var trail_points := PackedVector2Array([
			sword_start + trail_perp * 1.5,
			trail_end + trail_perp * 0.5,
			trail_end - trail_perp * 0.5,
			sword_start - trail_perp * 1.5,
		])
		draw_colored_polygon(trail_points, trail_color)

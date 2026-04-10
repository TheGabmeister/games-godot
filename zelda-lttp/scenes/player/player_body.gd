extends Node2D

# Draws the player using primitive shapes:
# Green pentagon torso, skin-tone circle head, directional cap triangle

@onready var player: Player = get_parent()

var _sword_arc_alpha: float = 0.0


func _process(_delta: float) -> void:
	if PlayerState.has_upgrade(&"shield"):
		queue_redraw()


func _draw() -> void:
	if not player:
		return

	# Item-get pose: arms up, item overhead
	if player.has_meta("item_get_active") and player.get_meta("item_get_active"):
		_draw_item_get_pose()
		return

	# Bunny form in Dark World without Moon Pearl
	if player.is_bunny:
		_draw_bunny_form()
		return

	var facing := player.facing_direction

	# Swim tint
	var is_swimming: bool = player.state_machine and player.state_machine.current_state and player.state_machine.current_state.name == &"Swim"

	# Body: green pentagon (simplified as a rectangle with angled top)
	var body_color := Color(0.2, 0.65, 0.2)
	if is_swimming:
		body_color = body_color.darkened(0.3)
	var body_points := PackedVector2Array([
		Vector2(-5, -2),
		Vector2(5, -2),
		Vector2(6, 6),
		Vector2(-6, 6),
	])
	if is_swimming:
		# Only draw upper body when swimming
		body_points = PackedVector2Array([
			Vector2(-5, -2),
			Vector2(5, -2),
			Vector2(5, 2),
			Vector2(-5, 2),
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

	# Shield always visible when owned (passive protection)
	if not is_swimming and PlayerState.has_upgrade(&"shield"):
		_draw_shield(facing)

	# Sword arc during attack
	if player.sword_active:
		_draw_sword_arc()

	# Water ripple when swimming
	if is_swimming:
		var ripple_color := Color(0.3, 0.5, 0.9, 0.4)
		draw_arc(Vector2(0, 3), 7.0, 0.0, PI, 8, ripple_color, 1.0)


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


func _draw_item_get_pose() -> void:
	# Body shifted up slightly, arms raised
	var body_color := Color(0.2, 0.65, 0.2)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-5, -1),
		Vector2(5, -1),
		Vector2(6, 6),
		Vector2(-6, 6),
	]), body_color)

	# Arms up
	draw_line(Vector2(-5, 0), Vector2(-6, -8), body_color, 2.0)
	draw_line(Vector2(5, 0), Vector2(6, -8), body_color, 2.0)

	# Head
	draw_circle(Vector2(0, -4), 4.0, Color(0.95, 0.8, 0.6))

	# Cap facing down (neutral)
	var cap_color := Color(0.15, 0.5, 0.15)
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, 4), Vector2(-3, -1), Vector2(3, -1),
	]), cap_color)

	# Item above head
	var item_data: ItemData = player.get_meta("item_get_data", null) as ItemData
	if item_data and item_data.icon_shape.size() > 0:
		var item_offset := Vector2(0, -14)
		var points := PackedVector2Array()
		for p in item_data.icon_shape:
			points.append(p + item_offset)
		draw_colored_polygon(points, item_data.icon_color)
	elif item_data:
		draw_circle(Vector2(0, -14), 4.0, item_data.icon_color)


func _draw_bunny_form() -> void:
	var facing := player.facing_direction
	# Pink bunny body
	var body_color := Color(0.9, 0.6, 0.7)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-4, -1), Vector2(4, -1),
		Vector2(5, 5), Vector2(-5, 5),
	]), body_color)
	# Head
	draw_circle(Vector2(0, -3), 3.5, body_color.lightened(0.1))
	# Ears
	var ear_dir := facing.normalized() if facing != Vector2.ZERO else Vector2.DOWN
	var ear_perp := Vector2(-ear_dir.y, ear_dir.x)
	var ear_base := Vector2(0, -5)
	draw_line(ear_base + ear_perp * 2, ear_base + ear_perp * 2 + Vector2(0, -6), body_color, 2.0)
	draw_line(ear_base - ear_perp * 2, ear_base - ear_perp * 2 + Vector2(0, -6), body_color, 2.0)
	# Inner ears
	draw_line(ear_base + ear_perp * 2, ear_base + ear_perp * 2 + Vector2(0, -5), Color(0.95, 0.7, 0.75), 1.0)
	draw_line(ear_base - ear_perp * 2, ear_base - ear_perp * 2 + Vector2(0, -5), Color(0.95, 0.7, 0.75), 1.0)
	# Eyes
	draw_circle(Vector2(-1.5, -3), 1.0, Color(0.2, 0.1, 0.1))
	draw_circle(Vector2(1.5, -3), 1.0, Color(0.2, 0.1, 0.1))


func _draw_shield(facing: Vector2) -> void:
	var tier: int = PlayerState.get_upgrade(&"shield")
	var shield_color: Color
	match tier:
		1: shield_color = Color(0.3, 0.5, 0.8)
		2: shield_color = Color(0.9, 0.3, 0.2)
		3: shield_color = Color(0.9, 0.85, 0.3)
		_: return

	# Position shield in front of player
	var offset: Vector2 = facing.normalized() * 7.0
	var perp: Vector2 = Vector2(-facing.y, facing.x).normalized()
	var center: Vector2 = offset

	# Shield shape: pointed kite
	var points := PackedVector2Array([
		center - perp * 4.0,
		center + facing.normalized() * 3.0,
		center + perp * 4.0,
		center - facing.normalized() * 5.0,
	])
	draw_colored_polygon(points, shield_color)
	draw_polyline(points, shield_color.lightened(0.3), 1.0)

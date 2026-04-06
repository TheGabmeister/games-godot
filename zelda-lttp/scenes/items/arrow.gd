extends Projectile

func _ready() -> void:
	speed = 140.0
	damage = 2
	damage_type = DamageType.Type.ARROW
	source_team = &"player"
	projectile_color = Color(0.6, 0.4, 0.2)
	projectile_radius = 2.0
	lifetime = 2.0
	super._ready()


func _draw() -> void:
	# Arrow shape: thin line with arrowhead
	var dir := direction.normalized()
	var perp := Vector2(-dir.y, dir.x)
	var tip := dir * 5.0
	var tail := -dir * 5.0
	draw_line(tail, tip, projectile_color, 1.5)
	# Arrowhead
	draw_colored_polygon(PackedVector2Array([
		tip,
		tip - dir * 3.0 + perp * 2.0,
		tip - dir * 3.0 - perp * 2.0,
	]), projectile_color)

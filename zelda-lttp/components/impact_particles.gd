class_name ImpactParticles extends Node

## Utility for spawning one-shot particle bursts at a position.
## Call the static methods from anywhere — they create temporary GPUParticles2D nodes.


static func sword_hit(tree: SceneTree, pos: Vector2) -> void:
	_burst(tree, pos, 8, Color(1.0, 1.0, 0.7), 0.15, 80.0)


static func enemy_death(tree: SceneTree, pos: Vector2, body_color: Color) -> void:
	_burst(tree, pos, 10, body_color, 0.4, 60.0)


static func bomb_explosion(tree: SceneTree, pos: Vector2) -> void:
	_burst(tree, pos, 18, Color(1.0, 0.5, 0.1), 0.3, 120.0)


static func water_splash(tree: SceneTree, pos: Vector2) -> void:
	_burst(tree, pos, 6, Color(0.3, 0.6, 1.0), 0.25, 50.0)


static func chest_sparkle(tree: SceneTree, pos: Vector2) -> void:
	_burst(tree, pos, 8, Color(1.0, 0.85, 0.2), 0.5, 30.0, true)


static func _burst(tree: SceneTree, pos: Vector2, count: int, color: Color, lifetime: float, speed: float, rise: bool = false) -> void:
	var root := tree.current_scene
	if not root:
		return

	# Use CPUParticles2D for simplicity — no process material resource needed
	var particles := CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = count
	particles.lifetime = lifetime
	particles.global_position = pos

	# Shape
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 2.0

	# Movement
	particles.direction = Vector2.UP if rise else Vector2(0, -1)
	particles.spread = 180.0 if not rise else 45.0
	particles.initial_velocity_min = speed * 0.5
	particles.initial_velocity_max = speed
	particles.gravity = Vector2(0, 40.0) if not rise else Vector2(0, -20.0)

	# Visual
	particles.scale_amount_min = 1.0
	particles.scale_amount_max = 2.0
	particles.color = color

	# Auto-free after particles finish
	root.add_child(particles)
	tree.create_timer(lifetime + 0.1).timeout.connect(particles.queue_free)

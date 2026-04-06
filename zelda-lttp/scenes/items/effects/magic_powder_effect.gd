extends BaseItemEffect

const LOCK_DURATION := 0.3


func can_use(_player: CharacterBody2D) -> bool:
	var cost: int = 4
	if PlayerState.has_upgrade(&"magic_halver"):
		cost = ceili(cost / 2.0)
	return PlayerState.current_magic >= cost


func activate(player: CharacterBody2D) -> float:
	# Create particle cone in facing direction
	var particles := GPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 12
	particles.lifetime = 0.5
	particles.global_position = player.global_position + player.facing_direction * 10.0

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(player.facing_direction.x, player.facing_direction.y, 0)
	mat.spread = 30.0
	mat.initial_velocity_min = 20.0
	mat.initial_velocity_max = 40.0
	mat.gravity = Vector3.ZERO
	mat.color = Color(0.6, 0.9, 0.3, 0.8)
	particles.process_material = mat

	player.get_parent().add_child(particles)

	# Auto-cleanup
	var tween: Tween = particles.create_tween()
	tween.tween_interval(1.0)
	tween.tween_callback(particles.queue_free)

	return LOCK_DURATION

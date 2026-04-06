extends Node2D

const FUSE_TIME := 2.5
const EXPLOSION_RADIUS := 24.0
const EXPLOSION_DAMAGE := 4

var _fuse_timer: float = FUSE_TIME
var _exploded: bool = false


func _ready() -> void:
	AudioManager.play_sfx(&"bomb_place")


func _physics_process(delta: float) -> void:
	if _exploded:
		return
	_fuse_timer -= delta

	# Flash faster as fuse runs out
	if _fuse_timer < 1.0:
		var flash_rate: float = 8.0 + (1.0 - _fuse_timer) * 12.0
		modulate.a = 0.5 + 0.5 * sin(_fuse_timer * flash_rate * TAU)

	if _fuse_timer <= 0.0:
		_explode()


func _explode() -> void:
	_exploded = true
	AudioManager.play_sfx(&"bomb_explode")
	EventBus.screen_shake_requested.emit(2.0, 0.2)

	# Create explosion Area2D to detect hits
	var explosion := Area2D.new()
	explosion.collision_layer = 8  # PlayerAttacks
	explosion.collision_mask = 4   # Enemies
	explosion.set_meta("damage", EXPLOSION_DAMAGE)
	explosion.set_meta("damage_type", DamageType.Type.BOMB)
	explosion.set_meta("knockback_force", 150.0)
	explosion.set_meta("source_team", &"player")
	explosion.set_meta("source_position", global_position)

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = EXPLOSION_RADIUS
	shape.shape = circle
	explosion.add_child(shape)
	explosion.global_position = global_position
	get_parent().add_child(explosion)

	# Explosion particles
	var particles := CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 16
	particles.lifetime = 0.4
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.initial_velocity_min = 30.0
	particles.initial_velocity_max = 80.0
	particles.gravity = Vector2(0, 50)
	particles.color = Color(1.0, 0.6, 0.2)
	particles.global_position = global_position
	get_parent().add_child(particles)

	# Cleanup after brief delay
	var tween: Tween = explosion.create_tween()
	tween.tween_interval(0.1)
	tween.tween_callback(explosion.queue_free)

	var tween2: Tween = particles.create_tween()
	tween2.tween_interval(1.0)
	tween2.tween_callback(particles.queue_free)

	queue_free()


func _draw() -> void:
	# Round bomb shape
	draw_circle(Vector2.ZERO, 5.0, Color(0.15, 0.15, 0.15))
	draw_circle(Vector2(0, -3), 1.5, Color(0.9, 0.5, 0.1))  # fuse spark

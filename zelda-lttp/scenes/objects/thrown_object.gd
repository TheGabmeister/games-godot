class_name ThrownObject extends Area2D
## Lightweight projectile created when the player throws a destructible.

var direction: Vector2 = Vector2.DOWN
var speed: float = 140.0
var damage: int = 2
var drop_table: LootTable
var visual_color: Color = Color(0.5, 0.4, 0.3)
var visual_type: StringName = &"pot"  # pot, bush, skull, sign
var persist_id: StringName = &""
var persist_room_id: StringName = &""

var _lifetime: float = 0.0
const MAX_LIFETIME := 1.5


func _ready() -> void:
	collision_layer = 8   # PlayerAttacks
	collision_mask = 5    # World(1) + Enemies(4)
	monitoring = true
	monitorable = true

	# Hitbox metadata for HurtboxComponent detection
	set_meta("damage", damage)
	set_meta("damage_type", 0)  # CONTACT
	set_meta("knockback_force", 80.0)
	set_meta("source_position", global_position)
	set_meta("source_team", &"player")

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 5.0
	shape.shape = circle
	add_child(shape)

	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	_lifetime += delta
	if _lifetime >= MAX_LIFETIME:
		_shatter()
		return
	position += direction * speed * delta


func _on_body_entered(_body: Node2D) -> void:
	_shatter()


func _on_area_entered(area: Area2D) -> void:
	# Hit an enemy hurtbox
	if area.has_method("_on_area_entered"):
		pass  # HurtboxComponent will detect us via meta
	_shatter()


func _shatter() -> void:
	_persist_removal()
	_spawn_particles()
	_spawn_loot()
	AudioManager.play_sfx(&"bush_cut")
	queue_free()


func _persist_removal() -> void:
	if persist_id == &"" or persist_room_id == &"":
		return
	GameManager.set_flag("%s/%s" % [persist_room_id, persist_id], true)


func _spawn_loot() -> void:
	if not drop_table:
		return
	var items: Array[ItemData] = drop_table.roll()
	var pickup_scene: PackedScene = load("res://scenes/pickups/pickup.tscn")
	for item in items:
		var pickup: Node2D = pickup_scene.instantiate()
		pickup.item = item
		pickup.global_position = global_position
		get_parent().add_child(pickup)


func _spawn_particles() -> void:
	var particles := CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 6
	particles.lifetime = 0.3
	particles.speed_scale = 1.5
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.initial_velocity_min = 15.0
	particles.initial_velocity_max = 40.0
	particles.gravity = Vector2(0, 120)
	particles.color = visual_color
	particles.global_position = global_position
	get_parent().add_child(particles)
	var tween := particles.create_tween()
	tween.tween_interval(0.6)
	tween.tween_callback(particles.queue_free)


func _draw() -> void:
	match visual_type:
		&"bush":
			draw_circle(Vector2.ZERO, 6.0, Color(0.35, 0.65, 0.25))
		&"skull":
			draw_circle(Vector2.ZERO, 5.0, Color(0.75, 0.7, 0.65))
		&"sign":
			draw_rect(Rect2(-6, -4, 12, 8), Color(0.55, 0.4, 0.2))
		_:  # pot
			draw_rect(Rect2(-5, -5, 10, 10), Color(0.55, 0.38, 0.22))
			draw_rect(Rect2(-5, -6, 10, 2), Color(0.65, 0.48, 0.3))

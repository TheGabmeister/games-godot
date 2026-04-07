class_name Destructible extends StaticBody2D
## Base class for liftable/destroyable objects (bushes, pots, skulls, signs).

@export var weight: int = 0  # 0=bare hands, 1=power glove, 2=titan's mitt
@export var liftable: bool = true
@export var sword_destroyable: bool = false
@export var dash_destroyable: bool = false
@export var persist_id: StringName = &""
@export var drop_table: LootTable

var _destroyed: bool = false


func _ready() -> void:
	collision_layer = 1  # World
	collision_mask = 0

	if persist_id != &"":
		var room_id := _get_room_id()
		if room_id != &"" and GameManager.get_flag("%s/%s" % [room_id, persist_id]):
			queue_free()
			return

	_setup_interact_area()

	if sword_destroyable:
		_setup_hurtbox()

	queue_redraw()


func _setup_interact_area() -> void:
	var area := Area2D.new()
	area.name = "InteractArea"
	area.collision_layer = 32  # Interactables
	area.collision_mask = 0
	area.monitorable = true
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16, 16)
	shape.shape = rect
	area.add_child(shape)
	add_child(area)


func _setup_hurtbox() -> void:
	var area := Area2D.new()
	area.name = "DestructHurtbox"
	area.collision_layer = 4  # Enemies (same as damageable targets)
	area.collision_mask = 8   # PlayerAttacks
	area.monitoring = true
	area.monitorable = true
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(14, 14)
	shape.shape = rect
	area.add_child(shape)
	add_child(area)
	area.area_entered.connect(_on_sword_hit)


func _on_sword_hit(area: Area2D) -> void:
	if _destroyed:
		return
	if area.has_meta("damage") or area.has_meta("source_team"):
		destroy()


func interact() -> void:
	if _destroyed:
		return
	if liftable:
		_try_lift()


func _try_lift() -> void:
	if weight <= PlayerState.get_upgrade(&"gloves"):
		EventBus.lift_requested.emit(self)
	else:
		AudioManager.play_sfx(&"error")


func destroy() -> void:
	if _destroyed:
		return
	_destroyed = true
	_persist_removal()
	_spawn_loot()
	_spawn_destroy_particles()
	AudioManager.play_sfx(&"bush_cut")
	queue_free()


func dash_destroy() -> void:
	if dash_destroyable and not _destroyed:
		destroy()


func _persist_removal() -> void:
	if persist_id == &"":
		return
	var room_id := _get_room_id()
	if room_id != &"":
		GameManager.set_flag("%s/%s" % [room_id, persist_id], true)


func _spawn_loot() -> void:
	if drop_table:
		var items: Array[ItemData] = drop_table.roll()
		for item in items:
			var pickup_scene: PackedScene = load("res://scenes/pickups/pickup.tscn")
			var pickup: Node2D = pickup_scene.instantiate()
			pickup.item = item
			pickup.global_position = global_position
			get_parent().add_child(pickup)


func _spawn_destroy_particles() -> void:
	var particles := CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 6
	particles.lifetime = 0.4
	particles.speed_scale = 1.5
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.initial_velocity_min = 20.0
	particles.initial_velocity_max = 50.0
	particles.gravity = Vector2(0, 120)
	particles.color = _get_particle_color()
	particles.global_position = global_position
	get_parent().add_child(particles)
	# Auto-cleanup
	var tween := particles.create_tween()
	tween.tween_interval(0.8)
	tween.tween_callback(particles.queue_free)


func _get_particle_color() -> Color:
	return Color(0.5, 0.4, 0.3)


func _get_room_id() -> StringName:
	var node: Node = get_parent()
	while node:
		if "room_data" in node and node.room_data:
			return node.room_data.room_id
		node = node.get_parent()
	return &""


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if persist_id == &"" and liftable:
		warnings.append("persist_id is empty — destruction state won't persist.")
	return warnings

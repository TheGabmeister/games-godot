extends CharacterBody2D
class_name EnemyBase

const HIT_PAYLOAD_SCRIPT = preload("res://scripts/components/hit_payload.gd")

signal activation_changed(is_awake: bool)
signal enemy_defeated(enemy_id: StringName)
signal drop_spawned(drop: Node)

@export var data: Resource
@export var initial_patrol_direction := -1
@export var spawn_drop_on_defeat := true

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual_root: Node2D = $VisualRoot
@onready var status_label: Label = $VisualRoot/StatusLabel
@onready var hurtbox: Area2D = $Hurtbox
@onready var health_component: Node = $HealthComponent
@onready var vision_area: Area2D = $VisionArea
@onready var vision_shape: CollisionShape2D = $VisionArea/CollisionShape2D
@onready var contact_area: Area2D = $ContactArea
@onready var enemy_brain: Node = $EnemyBrain
@onready var drop_spawner: Node = $DropSpawner

var _spawn_position := Vector2.ZERO
var _horizontal_intent := 0.0
var _patrol_direction := -1
var _is_defeated := false
var _gravity := 980.0


func _ready() -> void:
	add_to_group(&"stage_resettable")
	_spawn_position = global_position
	_gravity = float(ProjectSettings.get_setting("physics/2d/default_gravity"))
	_apply_data()

	vision_area.body_entered.connect(_on_vision_area_body_entered)
	vision_area.body_exited.connect(_on_vision_area_body_exited)
	contact_area.area_entered.connect(_on_contact_area_area_entered)
	health_component.health_changed.connect(_on_health_changed)
	health_component.died.connect(_on_health_component_died)
	enemy_brain.awake_changed.connect(_on_enemy_brain_awake_changed)
	enemy_brain.state_changed.connect(_on_enemy_brain_state_changed)

	reset_for_stage_retry()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += _gravity * delta
	elif velocity.y > 0.0:
		velocity.y = 0.0

	velocity.x = _horizontal_intent * _get_patrol_speed()
	move_and_slide()


func get_enemy_id() -> StringName:
	return _data_value("enemy_id", &"enemy")


func is_awake() -> bool:
	return enemy_brain != null and bool(enemy_brain.call("is_awake"))


func is_defeated() -> bool:
	return _is_defeated


func get_patrol_direction() -> int:
	return _patrol_direction


func get_active_drop_count() -> int:
	return int(drop_spawner.call("get_active_drop_count")) if drop_spawner != null else 0


func set_horizontal_intent(intent: float) -> void:
	_horizontal_intent = clampf(intent, -1.0, 1.0)
	if visual_root != null and absf(_horizontal_intent) > 0.01:
		visual_root.scale.x = 1.0 if _horizontal_intent >= 0.0 else -1.0


func reverse_patrol_direction() -> void:
	_patrol_direction *= -1


func should_turn_at_patrol_edge() -> bool:
	var patrol_distance := _get_patrol_distance()
	if patrol_distance <= 0.0:
		return false

	if _patrol_direction < 0 and global_position.x <= _spawn_position.x - patrol_distance:
		return true

	if _patrol_direction > 0 and global_position.x >= _spawn_position.x + patrol_distance:
		return true

	return false


func get_debug_summary() -> String:
	var state_name: StringName = enemy_brain.call("get_state_name") if enemy_brain != null else &"NONE"
	return "%s | %s | HP %d/%d | Drops %d" % [
		get_enemy_id(),
		state_name,
		int(health_component.get("current_health")) if health_component != null else 0,
		int(health_component.get("max_health")) if health_component != null else 0,
		get_active_drop_count(),
	]


func reset_for_stage_retry() -> void:
	global_position = _spawn_position
	velocity = Vector2.ZERO
	_horizontal_intent = 0.0
	_patrol_direction = -1 if initial_patrol_direction < 0 else 1
	_is_defeated = false
	visible = true

	if collision_shape != null:
		collision_shape.disabled = false
	if hurtbox != null:
		hurtbox.monitorable = true
	if vision_area != null:
		vision_area.monitoring = true
	if contact_area != null:
		contact_area.monitoring = true
	if drop_spawner != null:
		drop_spawner.call("reset_for_stage_retry")
	if health_component != null:
		health_component.call("reset")
	if enemy_brain != null:
		enemy_brain.call("reset_brain")

	_refresh_status_label()


func _apply_data() -> void:
	if data == null:
		return

	if health_component != null:
		health_component.set("max_health", int(_data_value("max_health", 2)))
		health_component.set("team", &"enemy")

	if vision_shape != null and vision_shape.shape is CircleShape2D:
		var circle_shape := vision_shape.shape as CircleShape2D
		circle_shape.radius = float(_data_value("activation_range", 120.0))


func _get_patrol_speed() -> float:
	return float(_data_value("patrol_speed", 0.0))


func _get_patrol_distance() -> float:
	return float(_data_value("patrol_distance", 0.0))


func _is_player_body(body: Node) -> bool:
	return body != null and body.has_method("get_health_component") and body.has_method("get_camera_anchor")


func _on_vision_area_body_entered(body: Node) -> void:
	if _is_defeated or not _is_player_body(body):
		return

	enemy_brain.wake()


func _on_vision_area_body_exited(body: Node) -> void:
	if _is_defeated or not _is_player_body(body):
		return

	enemy_brain.sleep()


func _on_contact_area_area_entered(area: Area2D) -> void:
	if _is_defeated or not is_awake() or data == null:
		return

	if area == null or not area.has_method("apply_hit_payload"):
		return

	var x_direction := 1.0
	if area.global_position.x < global_position.x:
		x_direction = -1.0

	var payload := HIT_PAYLOAD_SCRIPT.create(
		self,
		&"enemy",
		_data_value("contact_weapon_id", &"enemy_contact"),
		int(_data_value("contact_damage", 1)),
		Vector2(absf((_data_value("contact_knockback", Vector2.ZERO) as Vector2).x) * x_direction, (_data_value("contact_knockback", Vector2.ZERO) as Vector2).y)
	)
	area.apply_hit_payload(payload)


func _on_health_changed(_current_health: int, _max_health: int) -> void:
	_refresh_status_label()


func _on_health_component_died() -> void:
	_is_defeated = true
	_horizontal_intent = 0.0
	visible = false

	if collision_shape != null:
		collision_shape.disabled = true
	if hurtbox != null:
		hurtbox.monitorable = false
	if vision_area != null:
		vision_area.monitoring = false
	if contact_area != null:
		contact_area.monitoring = false
	if enemy_brain != null:
		enemy_brain.call("notify_enemy_defeated")

	if spawn_drop_on_defeat and data != null and _data_value("drop_scene", null) != null and drop_spawner != null:
		var drop: Node = drop_spawner.call("spawn_drop", _data_value("drop_scene", null), global_position + Vector2(0.0, -14.0)) as Node
		if drop != null:
			drop_spawned.emit(drop)

	enemy_defeated.emit(get_enemy_id())
	_refresh_status_label()


func _on_enemy_brain_awake_changed(is_now_awake: bool) -> void:
	activation_changed.emit(is_now_awake)
	_refresh_status_label()


func _on_enemy_brain_state_changed(_previous_state: StringName, _new_state: StringName) -> void:
	_refresh_status_label()


func _refresh_status_label() -> void:
	if status_label == null:
		return

	status_label.text = get_debug_summary()


func _data_value(property_name: String, default_value: Variant) -> Variant:
	if data == null:
		return default_value

	var value: Variant = data.get(property_name)
	return default_value if value == null else value

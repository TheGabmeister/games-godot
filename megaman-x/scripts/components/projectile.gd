extends Area2D
class_name GameplayProjectile

signal projectile_hit(target: Node, payload: Dictionary)

@onready var visual_root: Node2D = $VisualRoot
@onready var sprite: Sprite2D = $VisualRoot/Sprite2D

var owner_team: StringName = &"neutral"
var weapon_id: StringName = &""
var damage := 1
var direction := 1
var speed := 420.0
var lifetime := 1.2
var knockback := Vector2(110.0, -20.0)
var spawn_position := Vector2.ZERO


func _ready() -> void:
	add_to_group(&"stage_resettable")
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


func configure(configuration: Dictionary) -> void:
	owner_team = configuration.get("team", owner_team)
	weapon_id = configuration.get("weapon_id", weapon_id)
	damage = int(configuration.get("damage", damage))
	direction = 1 if int(configuration.get("direction", direction)) >= 0 else -1
	speed = float(configuration.get("speed", speed))
	lifetime = float(configuration.get("lifetime", lifetime))
	knockback = configuration.get("knockback", knockback) as Vector2
	spawn_position = global_position

	var visual_scale: Vector2 = configuration.get("visual_scale", Vector2.ONE)
	var visual_color: Color = configuration.get("color", Color.WHITE)
	visual_root.scale = Vector2(absf(visual_scale.x) * direction, visual_scale.y)
	sprite.modulate = visual_color


func _physics_process(delta: float) -> void:
	global_position.x += speed * float(direction) * delta
	lifetime = maxf(lifetime - delta, 0.0)
	if lifetime == 0.0:
		queue_free()


func reset_for_stage_retry() -> void:
	queue_free()


func _build_payload() -> Dictionary:
	return HitPayload.create(
		self,
		owner_team,
		weapon_id,
		damage,
		Vector2(knockback.x * float(direction), knockback.y)
	)


func _on_area_entered(area: Area2D) -> void:
	if area == null or not area.has_method("apply_hit_payload"):
		return

	var payload := _build_payload()
	var accepted := bool(area.call("apply_hit_payload", payload))
	if accepted:
		projectile_hit.emit(area, payload)
		queue_free()


func _on_body_entered(_body: Node) -> void:
	queue_free()

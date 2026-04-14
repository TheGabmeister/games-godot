extends Area2D
class_name HazardArea

const HIT_PAYLOAD_SCRIPT = preload("res://scripts/components/hit_payload.gd")

@export var damage := 4
@export var team: StringName = &"hazard"
@export var weapon_id: StringName = &"hazard_contact"
@export var knockback := Vector2(0.0, -220.0)


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
	if not area.has_method("apply_hit_payload"):
		return

	var x_direction := 1.0
	if area.global_position.x < global_position.x:
		x_direction = -1.0

	var payload: Dictionary = HIT_PAYLOAD_SCRIPT.create(
		self,
		team,
		weapon_id,
		damage,
		Vector2(absf(knockback.x) * x_direction, knockback.y)
	)

	area.apply_hit_payload(payload)

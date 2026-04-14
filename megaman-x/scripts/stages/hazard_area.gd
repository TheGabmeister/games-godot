extends Area2D
class_name HazardArea

const HIT_PAYLOAD_SCRIPT = preload("res://scripts/components/hit_payload.gd")

enum HazardMode {
	DAMAGE,
	INSTANT_DEATH,
}

@export var hazard_mode := HazardMode.DAMAGE
@export var damage := 4
@export var team: StringName = &"hazard"
@export var weapon_id: StringName = &"hazard_contact"
@export var knockback := Vector2(0.0, -220.0)


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
	if not area.has_method("apply_hit_payload"):
		return

	var applied_damage := damage
	if hazard_mode == HazardMode.INSTANT_DEATH:
		applied_damage = maxi(applied_damage, 9999)

	var x_direction := 1.0
	if area.global_position.x < global_position.x:
		x_direction = -1.0

	var payload: Dictionary = HIT_PAYLOAD_SCRIPT.create(
		self,
		team,
		weapon_id,
		applied_damage,
		Vector2(absf(knockback.x) * x_direction, knockback.y)
	)

	area.apply_hit_payload(payload)

extends Node
class_name HealthComponent

signal health_changed(current_health: int, max_health: int)
signal damaged(payload: Dictionary, current_health: int)
signal died
signal revived

@export var max_health := 16
@export var team: StringName = &"neutral"
@export var invulnerability_duration := 0.0
@export var damage_modifiers_by_weapon: Dictionary = {}

var current_health := 16
var is_dead := false

var _invulnerability_remaining := 0.0


func _ready() -> void:
	reset()


func _process(delta: float) -> void:
	if _invulnerability_remaining <= 0.0:
		return

	_invulnerability_remaining = maxf(_invulnerability_remaining - delta, 0.0)


func apply_hit_payload(payload: Dictionary) -> bool:
	if payload == null:
		return false

	if is_dead:
		return false

	if _invulnerability_remaining > 0.0:
		return false

	var payload_team: StringName = payload.get("team", &"")
	if not team.is_empty() and payload_team == team:
		return false

	var payload_damage := int(payload.get("damage", 0))
	var payload_weapon_id := payload.get("weapon_id", &"") as StringName
	var damage_multiplier := get_damage_multiplier_for_weapon(payload_weapon_id)
	payload_damage = _apply_damage_multiplier(payload_damage, damage_multiplier)
	if payload_damage <= 0:
		return false

	var applied_payload := payload.duplicate(true)
	applied_payload["damage"] = payload_damage
	applied_payload["damage_multiplier"] = damage_multiplier

	current_health = maxi(current_health - payload_damage, 0)
	_invulnerability_remaining = invulnerability_duration
	health_changed.emit(current_health, max_health)
	damaged.emit(applied_payload, current_health)

	if current_health <= 0:
		is_dead = true
		died.emit()

	return true


func get_damage_multiplier_for_weapon(weapon_id: StringName) -> float:
	if weapon_id.is_empty():
		return 1.0

	for key in damage_modifiers_by_weapon.keys():
		if StringName(str(key)) == weapon_id:
			return maxf(float(damage_modifiers_by_weapon[key]), 0.0)

	return 1.0


func reset() -> void:
	current_health = max_health
	is_dead = false
	_invulnerability_remaining = 0.0
	health_changed.emit(current_health, max_health)
	revived.emit()


func heal(amount: int) -> int:
	if amount <= 0 or is_dead:
		return 0

	var previous_health := current_health
	current_health = mini(current_health + amount, max_health)
	var healed_amount := current_health - previous_health
	if healed_amount > 0:
		health_changed.emit(current_health, max_health)

	return healed_amount


func set_max_health_value(new_max_health: int, fill_to_full := false, heal_delta := 0) -> void:
	var was_dead := is_dead
	max_health = maxi(1, new_max_health)
	if fill_to_full:
		current_health = max_health
		is_dead = false
		_invulnerability_remaining = 0.0
	elif heal_delta > 0:
		current_health = mini(current_health + heal_delta, max_health)
	else:
		current_health = mini(current_health, max_health)

	health_changed.emit(current_health, max_health)
	if fill_to_full and was_dead:
		revived.emit()


func _apply_damage_multiplier(base_damage: int, damage_multiplier: float) -> int:
	if base_damage <= 0 or damage_multiplier <= 0.0:
		return 0

	return maxi(1, roundi(float(base_damage) * damage_multiplier))

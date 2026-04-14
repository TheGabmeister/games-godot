extends Node
class_name HealthComponent

signal health_changed(current_health: int, max_health: int)
signal damaged(payload: Dictionary, current_health: int)
signal died
signal revived

@export var max_health := 16
@export var team: StringName = &"neutral"
@export var invulnerability_duration := 0.0

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
	if payload_damage <= 0:
		return false

	current_health = maxi(current_health - payload_damage, 0)
	_invulnerability_remaining = invulnerability_duration
	health_changed.emit(current_health, max_health)
	damaged.emit(payload, current_health)

	if current_health <= 0:
		is_dead = true
		died.emit()

	return true


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

extends Node

const ARMOR_PART_IDS := [&"helmet", &"body", &"arms", &"legs"]

var intro_cleared := false
var dash_unlocked := false
var defeated_bosses: Dictionary = {}
var unlocked_weapons: Dictionary = {&"buster": true}
var collected_pickups: Dictionary = {}
var collected_heart_tanks: Dictionary = {}
var armor_parts: Dictionary = {}
var sub_tanks: Dictionary = {}


func _ready() -> void:
	reset_for_new_game()


func reset_for_new_game() -> void:
	intro_cleared = false
	dash_unlocked = false
	defeated_bosses.clear()
	collected_pickups.clear()
	collected_heart_tanks.clear()
	sub_tanks.clear()

	unlocked_weapons = {
		&"buster": true,
	}

	armor_parts.clear()
	for part_id in ARMOR_PART_IDS:
		armor_parts[part_id] = false


func to_dict() -> Dictionary:
	return {
		"intro_cleared": intro_cleared,
		"dash_unlocked": dash_unlocked,
		"defeated_bosses": _stringify_keys(defeated_bosses),
		"unlocked_weapons": _stringify_keys(unlocked_weapons),
		"collected_pickups": _stringify_keys(collected_pickups),
		"collected_heart_tanks": _stringify_keys(collected_heart_tanks),
		"armor_parts": _stringify_keys(armor_parts),
		"sub_tanks": _stringify_keys(sub_tanks),
	}


func from_dict(payload: Dictionary) -> void:
	reset_for_new_game()

	intro_cleared = bool(payload.get("intro_cleared", false))
	dash_unlocked = bool(payload.get("dash_unlocked", false))
	defeated_bosses = _normalize_string_name_keys(payload.get("defeated_bosses", {}))
	unlocked_weapons = _normalize_string_name_keys(payload.get("unlocked_weapons", {&"buster": true}))
	collected_pickups = _normalize_string_name_keys(payload.get("collected_pickups", {}))
	collected_heart_tanks = _normalize_string_name_keys(payload.get("collected_heart_tanks", {}))
	var loaded_armor_parts := _normalize_string_name_keys(payload.get("armor_parts", {}))
	for part_id in ARMOR_PART_IDS:
		armor_parts[part_id] = bool(loaded_armor_parts.get(part_id, armor_parts.get(part_id, false)))
	sub_tanks = _normalize_string_name_keys(payload.get("sub_tanks", {}))

	if not unlocked_weapons.has(&"buster"):
		unlocked_weapons[&"buster"] = true


func _stringify_keys(source: Dictionary) -> Dictionary:
	var normalized := {}
	for key in source.keys():
		normalized[str(key)] = _duplicate_variant(source[key])
	return normalized


func _normalize_string_name_keys(source: Variant) -> Dictionary:
	var normalized := {}
	if typeof(source) != TYPE_DICTIONARY:
		return normalized

	for key in (source as Dictionary).keys():
		normalized[StringName(str(key))] = _duplicate_variant(source[key])
	return normalized


func _duplicate_variant(value: Variant) -> Variant:
	if value is Dictionary or value is Array:
		return value.duplicate(true)
	return value

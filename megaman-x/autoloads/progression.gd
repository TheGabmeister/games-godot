extends Node

const WEAPON_CATALOG_SCRIPT = preload("res://scripts/player/weapon_catalog.gd")

const ARMOR_PART_IDS := [&"helmet", &"body", &"arms", &"legs"]
const HEART_TANK_HEALTH_BONUS := 2
const SUB_TANK_MAX_FILL := 32
const MAVERICK_BOSS_IDS := [
	&"chill_penguin",
	&"storm_eagle",
	&"flame_mammoth",
	&"spark_mandrill",
	&"armored_armadillo",
	&"launch_octopus",
	&"boomer_kuwanger",
	&"sting_chameleon",
]
const FINAL_STAGE_ID := &"sigma_fortress_4"

signal progression_changed

var intro_cleared := false
var dash_unlocked := false
var defeated_bosses: Dictionary = {}
var unlocked_weapons: Dictionary = {&"buster": true}
var cleared_stages: Dictionary = {}
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
	cleared_stages.clear()
	collected_pickups.clear()
	collected_heart_tanks.clear()
	sub_tanks.clear()

	unlocked_weapons = {
		&"buster": true,
	}

	armor_parts.clear()
	for part_id in ARMOR_PART_IDS:
		armor_parts[part_id] = false

	progression_changed.emit()


func to_dict() -> Dictionary:
	return {
		"intro_cleared": intro_cleared,
		"dash_unlocked": dash_unlocked,
		"defeated_bosses": _stringify_keys(defeated_bosses),
		"unlocked_weapons": _stringify_keys(unlocked_weapons),
		"cleared_stages": _stringify_keys(cleared_stages),
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
	cleared_stages = _normalize_string_name_keys(payload.get("cleared_stages", {}))
	collected_pickups = _normalize_string_name_keys(payload.get("collected_pickups", {}))
	collected_heart_tanks = _normalize_string_name_keys(payload.get("collected_heart_tanks", {}))
	var loaded_armor_parts := _normalize_string_name_keys(payload.get("armor_parts", {}))
	for part_id in ARMOR_PART_IDS:
		armor_parts[part_id] = bool(loaded_armor_parts.get(part_id, armor_parts.get(part_id, false)))
	sub_tanks = _normalize_string_name_keys(payload.get("sub_tanks", {}))

	if not unlocked_weapons.has(&"buster"):
		unlocked_weapons[&"buster"] = true

	progression_changed.emit()


func has_collected_pickup(pickup_id: StringName) -> bool:
	return bool(collected_pickups.get(pickup_id, false))


func collect_pickup(pickup_id: StringName) -> bool:
	if pickup_id.is_empty() or has_collected_pickup(pickup_id):
		return false

	collected_pickups[pickup_id] = true
	progression_changed.emit()
	return true


func has_heart_tank_collected(pickup_id: StringName) -> bool:
	return bool(collected_heart_tanks.get(pickup_id, false))


func collect_heart_tank(pickup_id: StringName) -> bool:
	if pickup_id.is_empty() or has_heart_tank_collected(pickup_id):
		return false

	collected_heart_tanks[pickup_id] = true
	collected_pickups[pickup_id] = true
	progression_changed.emit()
	return true


func get_heart_tank_count() -> int:
	return collected_heart_tanks.size()


func get_heart_tank_health_bonus() -> int:
	return get_heart_tank_count() * HEART_TANK_HEALTH_BONUS


func unlock_dash() -> bool:
	if dash_unlocked:
		return false

	dash_unlocked = true
	progression_changed.emit()
	return true


func mark_intro_cleared() -> bool:
	if intro_cleared:
		return false

	intro_cleared = true
	progression_changed.emit()
	return true


func has_stage_cleared(stage_id: StringName) -> bool:
	return bool(cleared_stages.get(stage_id, false))


func mark_stage_cleared(stage_id: StringName) -> bool:
	if stage_id.is_empty() or has_stage_cleared(stage_id):
		return false

	cleared_stages[stage_id] = true
	progression_changed.emit()
	return true


func has_defeated_boss(boss_id: StringName) -> bool:
	return bool(defeated_bosses.get(boss_id, false))


func mark_boss_defeated(boss_id: StringName, weapon_id: StringName = &"") -> bool:
	if boss_id.is_empty() or has_defeated_boss(boss_id):
		return false

	defeated_bosses[boss_id] = true
	if not weapon_id.is_empty():
		unlocked_weapons[weapon_id] = true
	progression_changed.emit()
	return true


func have_all_mavericks_been_defeated() -> bool:
	for boss_id in MAVERICK_BOSS_IDS:
		if not has_defeated_boss(boss_id):
			return false

	return true


func is_campaign_complete() -> bool:
	return has_stage_cleared(FINAL_STAGE_ID)


func has_weapon_unlocked(weapon_id: StringName) -> bool:
	return bool(unlocked_weapons.get(weapon_id, false))


func unlock_weapon(weapon_id: StringName) -> bool:
	if weapon_id.is_empty() or has_weapon_unlocked(weapon_id):
		return false

	unlocked_weapons[weapon_id] = true
	progression_changed.emit()
	return true


func unlock_all_weapons() -> bool:
	var changed := false
	for weapon in WEAPON_CATALOG_SCRIPT.get_weapon_order():
		if weapon == null or weapon.weapon_id == &"buster":
			continue

		if not has_weapon_unlocked(weapon.weapon_id):
			unlocked_weapons[weapon.weapon_id] = true
			changed = true

	if changed:
		progression_changed.emit()

	return changed


func has_armor_part(part_id: StringName) -> bool:
	return bool(armor_parts.get(part_id, false))


func unlock_armor_part(part_id: StringName, pickup_id: StringName = &"") -> bool:
	if part_id.is_empty() or has_armor_part(part_id):
		return false

	armor_parts[part_id] = true
	if not pickup_id.is_empty():
		collected_pickups[pickup_id] = true
	progression_changed.emit()
	return true


func has_sub_tank(sub_tank_id: StringName) -> bool:
	return bool((sub_tanks.get(sub_tank_id, {}) as Dictionary).get("owned", false))


func get_sub_tank_fill(sub_tank_id: StringName) -> int:
	return int((sub_tanks.get(sub_tank_id, {}) as Dictionary).get("fill", 0))


func get_owned_sub_tank_ids() -> Array[StringName]:
	var owned_ids: Array[StringName] = []
	for key in sub_tanks.keys():
		var sub_tank_id := key as StringName
		if has_sub_tank(sub_tank_id):
			owned_ids.append(sub_tank_id)

	return owned_ids


func acquire_sub_tank(sub_tank_id: StringName, pickup_id: StringName = &"", initial_fill := 0) -> bool:
	if sub_tank_id.is_empty() or has_sub_tank(sub_tank_id):
		return false

	sub_tanks[sub_tank_id] = {
		"owned": true,
		"fill": clampi(initial_fill, 0, SUB_TANK_MAX_FILL),
	}
	if not pickup_id.is_empty():
		collected_pickups[pickup_id] = true
	progression_changed.emit()
	return true


func refill_sub_tank(sub_tank_id: StringName, amount: int) -> int:
	if amount <= 0 or not has_sub_tank(sub_tank_id):
		return 0

	var sub_tank := (sub_tanks.get(sub_tank_id, {}) as Dictionary).duplicate(true)
	var previous_fill := int(sub_tank.get("fill", 0))
	var next_fill := clampi(previous_fill + amount, 0, SUB_TANK_MAX_FILL)
	if next_fill == previous_fill:
		return 0

	sub_tank["owned"] = true
	sub_tank["fill"] = next_fill
	sub_tanks[sub_tank_id] = sub_tank
	progression_changed.emit()
	return next_fill - previous_fill


func use_sub_tank_heal(requested_heal: int) -> Dictionary:
	var result := {
		"used": false,
		"sub_tank_id": StringName(),
		"heal_amount": 0,
		"remaining_fill": 0,
	}
	if requested_heal <= 0:
		return result

	var owned_ids := get_owned_sub_tank_ids()
	owned_ids.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	for sub_tank_id in owned_ids:
		var current_fill := get_sub_tank_fill(sub_tank_id)
		if current_fill <= 0:
			continue

		var used_amount := mini(current_fill, requested_heal)
		var sub_tank := (sub_tanks.get(sub_tank_id, {}) as Dictionary).duplicate(true)
		sub_tank["owned"] = true
		sub_tank["fill"] = current_fill - used_amount
		sub_tanks[sub_tank_id] = sub_tank
		progression_changed.emit()
		result["used"] = true
		result["sub_tank_id"] = sub_tank_id
		result["heal_amount"] = used_amount
		result["remaining_fill"] = int(sub_tank["fill"])
		return result

	return result


func grant_dash_unlock(pickup_id: StringName) -> bool:
	var changed := unlock_dash()
	if not pickup_id.is_empty():
		changed = collect_pickup(pickup_id) or changed
	return changed


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

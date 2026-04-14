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
		"defeated_bosses": defeated_bosses.duplicate(true),
		"unlocked_weapons": unlocked_weapons.duplicate(true),
		"collected_pickups": collected_pickups.duplicate(true),
		"collected_heart_tanks": collected_heart_tanks.duplicate(true),
		"armor_parts": armor_parts.duplicate(true),
		"sub_tanks": sub_tanks.duplicate(true),
	}


func from_dict(payload: Dictionary) -> void:
	reset_for_new_game()

	intro_cleared = bool(payload.get("intro_cleared", false))
	dash_unlocked = bool(payload.get("dash_unlocked", false))
	defeated_bosses = payload.get("defeated_bosses", {}).duplicate(true)
	unlocked_weapons = payload.get("unlocked_weapons", {&"buster": true}).duplicate(true)
	collected_pickups = payload.get("collected_pickups", {}).duplicate(true)
	collected_heart_tanks = payload.get("collected_heart_tanks", {}).duplicate(true)
	armor_parts = payload.get("armor_parts", armor_parts).duplicate(true)
	sub_tanks = payload.get("sub_tanks", {}).duplicate(true)

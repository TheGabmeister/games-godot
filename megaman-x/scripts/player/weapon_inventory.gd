extends Node
class_name WeaponInventory

const DEFAULT_WEAPON_PATH := "res://data/weapons/buster.tres"

signal current_weapon_changed(weapon_id: StringName, display_name: String)

@export var weapon_order: Array[WeaponData] = []

var _current_index := 0


func _ready() -> void:
	if weapon_order.is_empty():
		var default_weapon := load(DEFAULT_WEAPON_PATH) as WeaponData
		if default_weapon != null:
			weapon_order.append(default_weapon)

	_emit_current_weapon_changed()


func get_current_weapon() -> WeaponData:
	if weapon_order.is_empty():
		return null

	_current_index = clampi(_current_index, 0, weapon_order.size() - 1)
	return weapon_order[_current_index]


func cycle_next() -> bool:
	if weapon_order.size() <= 1:
		return false

	_current_index = (_current_index + 1) % weapon_order.size()
	_emit_current_weapon_changed()
	return true


func cycle_previous() -> bool:
	if weapon_order.size() <= 1:
		return false

	_current_index -= 1
	if _current_index < 0:
		_current_index = weapon_order.size() - 1

	_emit_current_weapon_changed()
	return true


func _emit_current_weapon_changed() -> void:
	var current_weapon := get_current_weapon()
	if current_weapon == null:
		current_weapon_changed.emit(&"", "Offline")
		return

	current_weapon_changed.emit(current_weapon.weapon_id, current_weapon.display_name)

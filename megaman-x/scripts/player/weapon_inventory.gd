extends Node
class_name WeaponInventory

const WEAPON_CATALOG_SCRIPT = preload("res://scripts/player/weapon_catalog.gd")

signal current_weapon_changed(weapon_id: StringName, display_name: String)
signal inventory_changed

@export var weapon_order: Array[WeaponData] = []

var _current_index := 0
var _progression: Node = null


func _ready() -> void:
	if weapon_order.is_empty():
		weapon_order = WEAPON_CATALOG_SCRIPT.get_weapon_order()

	_progression = get_node_or_null("/root/Progression")
	if _progression != null and _progression.has_signal("progression_changed"):
		_progression.progression_changed.connect(_on_progression_changed)

	_sync_current_index()
	_emit_current_weapon_changed()


func get_current_weapon() -> WeaponData:
	if weapon_order.is_empty():
		return null

	_sync_current_index()
	return weapon_order[_current_index]


func cycle_next() -> bool:
	if get_unlocked_weapon_count() <= 1:
		return false

	var start_index := _current_index
	for step in range(1, weapon_order.size() + 1):
		var candidate_index := (start_index + step) % weapon_order.size()
		if _is_index_unlocked(candidate_index):
			_current_index = candidate_index
			_emit_current_weapon_changed()
			return true

	return false


func cycle_previous() -> bool:
	if get_unlocked_weapon_count() <= 1:
		return false

	var start_index := _current_index
	for step in range(1, weapon_order.size() + 1):
		var candidate_index := start_index - step
		if candidate_index < 0:
			candidate_index += weapon_order.size()
		if _is_index_unlocked(candidate_index):
			_current_index = candidate_index
			_emit_current_weapon_changed()
			return true

	return false


func equip_weapon(weapon_id: StringName) -> bool:
	for index in range(weapon_order.size()):
		var weapon := weapon_order[index]
		if weapon != null and weapon.weapon_id == weapon_id and _is_index_unlocked(index):
			_current_index = index
			_emit_current_weapon_changed()
			return true

	return false


func has_weapon_unlocked(weapon_id: StringName) -> bool:
	return _is_weapon_unlocked(weapon_id)


func get_unlocked_weapon_count() -> int:
	return get_unlocked_weapon_ids().size()


func get_unlocked_weapon_ids() -> Array[StringName]:
	var unlocked_ids: Array[StringName] = []
	for weapon in weapon_order:
		if weapon != null and _is_weapon_unlocked(weapon.weapon_id):
			unlocked_ids.append(weapon.weapon_id)

	return unlocked_ids


func _sync_current_index() -> void:
	if weapon_order.is_empty():
		_current_index = 0
		return

	_current_index = clampi(_current_index, 0, weapon_order.size() - 1)
	if _is_index_unlocked(_current_index):
		return

	for index in range(weapon_order.size()):
		if _is_index_unlocked(index):
			_current_index = index
			return

	_current_index = 0


func _is_index_unlocked(index: int) -> bool:
	if index < 0 or index >= weapon_order.size():
		return false

	var weapon := weapon_order[index]
	return weapon != null and _is_weapon_unlocked(weapon.weapon_id)


func _is_weapon_unlocked(weapon_id: StringName) -> bool:
	if weapon_id == &"buster":
		return true

	if _progression == null:
		_progression = get_node_or_null("/root/Progression")

	return bool(_progression != null and _progression.has_method("has_weapon_unlocked") and _progression.has_weapon_unlocked(weapon_id))


func _on_progression_changed() -> void:
	var previous_weapon := get_current_weapon()
	var previous_weapon_id := previous_weapon.weapon_id if previous_weapon != null else StringName()
	_sync_current_index()
	inventory_changed.emit()

	var current_weapon := get_current_weapon()
	var current_weapon_id := current_weapon.weapon_id if current_weapon != null else StringName()
	if current_weapon_id != previous_weapon_id:
		_emit_current_weapon_changed()


func _emit_current_weapon_changed() -> void:
	var current_weapon := get_current_weapon()
	if current_weapon == null:
		current_weapon_changed.emit(&"", "Offline")
		return

	current_weapon_changed.emit(current_weapon.weapon_id, current_weapon.display_name)

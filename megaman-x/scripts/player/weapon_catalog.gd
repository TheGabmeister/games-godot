extends RefCounted
class_name WeaponCatalog

const WEAPON_RESOURCE_PATHS := [
	"res://data/weapons/buster.tres",
	"res://data/weapons/shotgun_ice.tres",
	"res://data/weapons/storm_tornado.tres",
	"res://data/weapons/fire_wave.tres",
	"res://data/weapons/electric_spark.tres",
	"res://data/weapons/rolling_shield.tres",
	"res://data/weapons/homing_torpedo.tres",
	"res://data/weapons/boomerang_cutter.tres",
	"res://data/weapons/chameleon_sting.tres",
]

static var _weapon_order: Array[WeaponData] = []
static var _weapon_by_id: Dictionary = {}


static func get_weapon_order() -> Array[WeaponData]:
	_ensure_loaded()
	return _weapon_order.duplicate()


static func get_weapon_data(weapon_id: StringName) -> WeaponData:
	_ensure_loaded()
	return _weapon_by_id.get(weapon_id) as WeaponData


static func get_weapon_display_name(weapon_id: StringName) -> String:
	var weapon := get_weapon_data(weapon_id)
	return weapon.display_name if weapon != null else String(weapon_id)


static func _ensure_loaded() -> void:
	if not _weapon_order.is_empty():
		return

	for resource_path in WEAPON_RESOURCE_PATHS:
		var weapon := load(resource_path) as WeaponData
		if weapon == null:
			push_error("WeaponCatalog failed to load weapon data at '%s'." % resource_path)
			continue

		_weapon_order.append(weapon)
		_weapon_by_id[weapon.weapon_id] = weapon

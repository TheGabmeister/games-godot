@tool
class_name ItemData extends Resource

enum ItemType {
	SKILL,
	UPGRADE,
	RESOURCE,
}

@export var id: StringName
@export var display_name: String
@export var description: String
@export var item_type: ItemType
@export var icon_color: Color = Color.WHITE
@export var icon_shape: PackedVector2Array

# SKILL items only:
@export var magic_cost: int
@export var ammo_type: StringName
@export var ammo_cost: int
@export var use_script: Script

# UPGRADE items only:
@export var upgrade_key: StringName
@export var tier: int

# RESOURCE items only:
@export var resource_key: StringName
@export var resource_amount: int


func _validate_property(property: Dictionary) -> void:
	var skill_fields := ["magic_cost", "ammo_type", "ammo_cost", "use_script"]
	var upgrade_fields := ["upgrade_key", "tier"]
	var resource_fields := ["resource_key", "resource_amount"]

	if property.name in skill_fields and item_type != ItemType.SKILL:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	elif property.name in upgrade_fields and item_type != ItemType.UPGRADE:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	elif property.name in resource_fields and item_type != ItemType.RESOURCE:
		property.usage = PROPERTY_USAGE_NO_EDITOR

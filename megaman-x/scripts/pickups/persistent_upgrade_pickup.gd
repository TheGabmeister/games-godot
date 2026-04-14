extends Area2D
class_name PersistentUpgradePickup

@export var pickup_id: StringName = &"persistent_pickup"
@export var pickup_kind: StringName = &"heart_tank"
@export var armor_part_id: StringName = &"body"
@export var sub_tank_id: StringName = &"sub_tank_alpha"
@export var initial_sub_tank_fill := 12

var _collected := false
var _base_label_text := ""

@onready var status_label: Label = $StatusLabel


func _ready() -> void:
	add_to_group(&"stage_resettable")
	add_to_group(&"player_pickup")
	_base_label_text = status_label.text if status_label != null else ""
	var progression := _get_progression()
	_collected = progression != null and progression.has_method("has_collected_pickup") and progression.has_collected_pickup(pickup_id)
	_apply_state()


func is_collected() -> bool:
	return _collected


func collect(pickup_receiver: Node) -> bool:
	if _collected or pickup_receiver == null:
		return false

	var accepted := false
	match pickup_kind:
		&"heart_tank":
			accepted = bool(pickup_receiver.call("collect_heart_tank", pickup_id, 2))
		&"armor_capsule":
			accepted = bool(pickup_receiver.call("collect_armor_part", armor_part_id, pickup_id))
		&"sub_tank":
			accepted = bool(pickup_receiver.call("collect_sub_tank", sub_tank_id, pickup_id, initial_sub_tank_fill))
		_:
			push_warning("PersistentUpgradePickup ignored unknown pickup kind '%s'." % pickup_kind)

	if accepted:
		_collected = true
		_apply_state()

	return accepted


func reset_for_stage_retry() -> void:
	_apply_state()


func _apply_state() -> void:
	var is_active := not _collected
	set_deferred("monitoring", false)
	set_deferred("monitorable", is_active)
	visible = not _collected
	if status_label == null:
		return

	status_label.text = "%s CLAIMED" % _base_label_text if _collected else _base_label_text


func _get_progression() -> Node:
	return get_node_or_null("/root/Progression")

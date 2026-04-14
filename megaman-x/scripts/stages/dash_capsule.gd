extends Area2D
class_name DashCapsule

signal triggered(pickup_id: StringName)
signal collected(pickup_id: StringName)

@export var pickup_id: StringName = &"dash_capsule"

var _triggered := false
var _collected := false

@onready var status_label: Label = $StatusLabel


func _ready() -> void:
	add_to_group(&"stage_resettable")
	body_entered.connect(_on_body_entered)
	_collected = Progression.has_method("has_collected_pickup") and Progression.has_collected_pickup(pickup_id)
	_apply_state()


func is_collected() -> bool:
	return _collected


func is_available() -> bool:
	return not _collected and not _triggered


func mark_collected() -> void:
	if _collected:
		return

	_collected = true
	_triggered = false
	_apply_state()
	collected.emit(pickup_id)


func reset_for_stage_retry() -> void:
	if _collected:
		return

	_triggered = false
	_apply_state()


func _on_body_entered(body: Node) -> void:
	if _collected or _triggered or body == null or not body.has_method("get_camera_anchor"):
		return

	_triggered = true
	_apply_state()
	triggered.emit(pickup_id)


func _apply_state() -> void:
	monitoring = not _collected and not _triggered
	monitorable = monitoring
	visible = not _collected
	if status_label == null:
		return

	if _collected:
		status_label.text = "CAPSULE CLAIMED"
	elif _triggered:
		status_label.text = "CAPSULE ACTIVE"
	else:
		status_label.text = "LEG CAPSULE"

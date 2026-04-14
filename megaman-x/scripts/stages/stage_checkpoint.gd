extends Area2D
class_name StageCheckpoint

signal activated(checkpoint_id: StringName)

@export var checkpoint_id: StringName = &"checkpoint"
@export var stage_controller_path: NodePath = NodePath("../StageController")
@export var respawn_anchor_path: NodePath = NodePath("RespawnAnchor")

@onready var stage_controller: StageController = get_node_or_null(stage_controller_path) as StageController
@onready var respawn_anchor: Marker2D = get_node_or_null(respawn_anchor_path) as Marker2D
@onready var base_polygon: Polygon2D = $Base
@onready var beacon_polygon: Polygon2D = $Beacon
@onready var status_label: Label = $StatusLabel

var _is_active := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if stage_controller != null:
		stage_controller.checkpoint_activated.connect(_on_stage_controller_checkpoint_activated)
		_is_active = stage_controller.get_active_checkpoint_id() == checkpoint_id
	_refresh_visuals()


func is_active() -> bool:
	return _is_active


func get_checkpoint_id() -> StringName:
	return checkpoint_id


func get_respawn_position() -> Vector2:
	return respawn_anchor.global_position if respawn_anchor != null else global_position


func _on_body_entered(body: Node) -> void:
	if body == null or not body.has_method("get_health_component") or stage_controller == null:
		return

	stage_controller.activate_checkpoint(checkpoint_id, get_respawn_position())


func _on_stage_controller_checkpoint_activated(new_checkpoint_id: StringName, _respawn_position: Vector2) -> void:
	_is_active = new_checkpoint_id == checkpoint_id
	_refresh_visuals()
	if _is_active:
		activated.emit(checkpoint_id)


func _refresh_visuals() -> void:
	if base_polygon != null:
		base_polygon.color = Color(0.996078, 0.807843, 0.333333, 1.0) if _is_active else Color(0.290196, 0.364706, 0.486275, 1.0)
	if beacon_polygon != null:
		beacon_polygon.color = Color(0.513726, 1.0, 0.784314, 0.95) if _is_active else Color(0.529412, 0.741176, 0.94902, 0.45)
	if status_label != null:
		status_label.text = "%s%s" % [checkpoint_id, " ACTIVE" if _is_active else ""]

extends Area2D
class_name StageClearTrigger

@export var trigger_id: StringName = &"goal"
@export var stage_controller_path: NodePath = NodePath("../StageController")

@onready var stage_controller: StageController = get_node_or_null(stage_controller_path) as StageController


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body == null or not body.has_method("get_health_component") or stage_controller == null:
		return

	stage_controller.begin_stage_clear(trigger_id)

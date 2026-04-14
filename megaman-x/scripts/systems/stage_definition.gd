extends Resource
class_name StageDefinition

@export var stage_id: StringName
@export var display_name := ""
@export_file("*.tscn") var scene_path := ""
@export var allow_direct_launch := true


func is_valid() -> bool:
	return not stage_id.is_empty() and not scene_path.is_empty()

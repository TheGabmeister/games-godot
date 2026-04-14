extends Resource
class_name StageDefinition

@export var stage_id: StringName
@export var display_name := ""
@export_file("*.tscn") var scene_path := ""
@export var stage_group: StringName = &"maverick"
@export var boss_id: StringName
@export var weapon_reward_id: StringName
@export var show_in_stage_select := true
@export var requires_intro_clear := false
@export var required_defeated_boss_ids: Array[StringName] = []
@export var required_stage_clear_ids: Array[StringName] = []
@export var allow_direct_launch := true


func is_valid() -> bool:
	return not stage_id.is_empty() and not scene_path.is_empty()

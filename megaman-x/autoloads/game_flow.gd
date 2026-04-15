extends Node

const WEAPON_CATALOG_SCRIPT = preload("res://scripts/player/weapon_catalog.gd")

enum RuntimeState {
	BOOT,
	TITLE,
	STAGE_SELECT,
	IN_STAGE,
	PAUSED,
	CUTSCENE,
	STAGE_CLEAR,
	ENDING,
}

const TITLE_SCREEN_SCENE_PATH := "res://scenes/ui/TitleScreen.tscn"
const STAGE_SELECT_SCENE_PATH := "res://scenes/ui/StageSelectMenu.tscn"
const ENDING_SCREEN_SCENE_PATH := "res://scenes/ui/EndingScreen.tscn"
const INTRO_STAGE_ID := &"intro_highway"
const FINAL_STAGE_ID := &"sigma_fortress_4"
const MAVERICK_BOSS_IDS: Array[StringName] = [
	&"chill_penguin",
	&"storm_eagle",
	&"flame_mammoth",
	&"spark_mandrill",
	&"armored_armadillo",
	&"launch_octopus",
	&"boomer_kuwanger",
	&"sting_chameleon",
]
const STAGE_REGISTRY_PATHS := [
	"res://data/stages/intro_highway.tres",
	"res://data/stages/chill_penguin.tres",
	"res://data/stages/storm_eagle.tres",
	"res://data/stages/flame_mammoth.tres",
	"res://data/stages/spark_mandrill.tres",
	"res://data/stages/armored_armadillo.tres",
	"res://data/stages/launch_octopus.tres",
	"res://data/stages/boomer_kuwanger.tres",
	"res://data/stages/sting_chameleon.tres",
	"res://data/stages/sigma_fortress_1.tres",
	"res://data/stages/sigma_fortress_2.tres",
	"res://data/stages/sigma_fortress_3.tres",
	"res://data/stages/sigma_fortress_4.tres",
	"res://data/stages/test_stage.tres",
]

signal state_changed(previous_state: int, new_state: int)
signal stage_changed(stage_id: StringName)
signal cutscene_started(stage_id: StringName, cutscene_id: StringName)
signal cutscene_finished(stage_id: StringName, cutscene_id: StringName)
signal stage_clear_started(stage_id: StringName)
signal ending_started(stage_id: StringName)

var current_state: int = RuntimeState.BOOT
var current_stage_id: StringName = &""

var _runtime_shell: Node = null
var _stage_registry: Dictionary = {}
var _stage_order: Array[StringName] = []


func _ready() -> void:
	_build_stage_registry()


func register_runtime_shell(runtime_shell: Node) -> void:
	_runtime_shell = runtime_shell
	call_deferred("_enter_boot_flow")


func get_registered_stage(stage_id: StringName) -> StageDefinition:
	return _stage_registry.get(stage_id) as StageDefinition


func get_registered_stage_ids() -> Array[StringName]:
	return _stage_order.duplicate()


func get_stage_select_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var progression := _get_progression()
	for stage_id in _stage_order:
		var definition := get_registered_stage(stage_id)
		if definition == null or not definition.show_in_stage_select:
			continue

		entries.append({
			"stage_id": definition.stage_id,
			"display_name": definition.display_name,
			"stage_group": definition.stage_group,
			"unlocked": is_stage_unlocked(definition.stage_id),
			"cleared": progression != null and progression.has_method("has_stage_cleared") and progression.has_stage_cleared(definition.stage_id),
		})

	return entries


func can_access_stage_select() -> bool:
	var progression := _get_progression()
	return bool(progression != null and progression.get("intro_cleared"))


func is_campaign_complete() -> bool:
	var progression := _get_progression()
	if progression == null:
		return false

	if progression.has_method("is_campaign_complete"):
		return progression.is_campaign_complete()

	return progression.has_method("has_stage_cleared") and progression.has_stage_cleared(FINAL_STAGE_ID)


func can_trigger_ending_from_stage(stage_id: StringName) -> bool:
	var definition := get_registered_stage(stage_id)
	if definition == null or not definition.triggers_ending_on_clear:
		return false

	return is_stage_unlocked(stage_id)


func is_stage_unlocked(stage_id: StringName) -> bool:
	var definition := get_registered_stage(stage_id)
	if definition == null:
		return false

	var progression := _get_progression()
	if progression == null:
		return false

	if definition.requires_intro_clear and not bool(progression.get("intro_cleared")):
		return false

	for boss_id in definition.required_defeated_boss_ids:
		if not progression.has_method("has_defeated_boss") or not progression.has_defeated_boss(boss_id):
			return false

	for required_stage_id in definition.required_stage_clear_ids:
		if not progression.has_method("has_stage_cleared") or not progression.has_stage_cleared(required_stage_id):
			return false

	return true


func request_title() -> void:
	current_stage_id = &""
	_set_state(RuntimeState.TITLE)

	if _runtime_shell != null and _runtime_shell.has_method("show_title_screen"):
		_runtime_shell.show_title_screen(TITLE_SCREEN_SCENE_PATH)


func request_stage_select() -> void:
	current_stage_id = &""
	_set_state(RuntimeState.STAGE_SELECT)

	if _runtime_shell != null and _runtime_shell.has_method("show_stage_select_screen"):
		_runtime_shell.show_stage_select_screen(STAGE_SELECT_SCENE_PATH)


func start_new_game() -> void:
	var progression := get_node_or_null("/root/Progression")
	if progression != null and progression.has_method("reset_for_new_game"):
		progression.reset_for_new_game()
	request_stage(INTRO_STAGE_ID)


func continue_from_save() -> bool:
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager == null or not save_manager.has_method("load_game"):
		return false

	var loaded := bool(save_manager.load_game())
	if loaded:
		var progression := _get_progression()
		if progression != null and bool(progression.get("intro_cleared")):
			request_stage_select()
		else:
			request_stage(INTRO_STAGE_ID)
	return loaded


func request_stage(stage_id: StringName) -> void:
	var stage_definition := get_registered_stage(stage_id)
	if stage_definition == null:
		push_error("GameFlow missing stage definition for '%s'." % stage_id)
		return

	if not is_stage_unlocked(stage_id):
		push_error("GameFlow rejected locked stage '%s'." % stage_id)
		return

	current_stage_id = stage_id
	_set_state(RuntimeState.IN_STAGE)

	if _runtime_shell != null and _runtime_shell.has_method("load_stage"):
		_runtime_shell.load_stage(stage_definition)

	stage_changed.emit(current_stage_id)


func request_cutscene(stage_id: StringName, payload: Dictionary = {}) -> void:
	if not stage_id.is_empty():
		current_stage_id = stage_id

	_set_state(RuntimeState.CUTSCENE)
	cutscene_started.emit(current_stage_id, payload.get("cutscene_id", &"") as StringName)


func finish_cutscene(stage_id: StringName = &"", payload: Dictionary = {}) -> void:
	if not stage_id.is_empty():
		current_stage_id = stage_id

	_set_state(RuntimeState.IN_STAGE)
	cutscene_finished.emit(current_stage_id, payload.get("cutscene_id", &"") as StringName)


func request_stage_clear(stage_id: StringName, payload: Dictionary = {}) -> void:
	if current_state == RuntimeState.STAGE_CLEAR and current_stage_id == stage_id:
		return

	var stage_definition := get_registered_stage(stage_id)
	var progression_result := _apply_stage_clear_progression(stage_definition)
	current_stage_id = stage_id
	_set_state(RuntimeState.STAGE_CLEAR)

	var overlay_payload := payload.duplicate(true)
	overlay_payload["stage_id"] = stage_id
	overlay_payload["display_name"] = stage_definition.display_name if stage_definition != null else String(stage_id)
	overlay_payload["progression_saved"] = bool(progression_result.get("progression_saved", false))
	overlay_payload["reward_weapon_id"] = progression_result.get("reward_weapon_id", &"") as StringName
	overlay_payload["reward_weapon_name"] = String(progression_result.get("reward_weapon_name", ""))
	overlay_payload["ordered_boss_ids"] = stage_definition.ordered_boss_ids.duplicate() if stage_definition != null else []

	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null and audio_manager.has_method("play_sfx"):
		audio_manager.play_sfx(&"stage_clear_fanfare")

	if stage_definition != null and stage_definition.triggers_ending_on_clear:
		_set_state(RuntimeState.ENDING)
		overlay_payload["campaign_complete"] = is_campaign_complete()
		if _runtime_shell != null and _runtime_shell.has_method("show_ending_screen"):
			_runtime_shell.show_ending_screen(ENDING_SCREEN_SCENE_PATH, overlay_payload)
		ending_started.emit(current_stage_id)
		return

	if _runtime_shell != null and _runtime_shell.has_method("show_stage_clear_overlay"):
		_runtime_shell.show_stage_clear_overlay(overlay_payload)

	stage_clear_started.emit(current_stage_id)


func exit_stage_clear_to_frontend() -> void:
	var stage_definition := get_registered_stage(current_stage_id)
	if can_access_stage_select() and stage_definition != null and (stage_definition.stage_id == INTRO_STAGE_ID or stage_definition.show_in_stage_select):
		request_stage_select()
		return

	request_title()


func exit_ending_to_title() -> void:
	request_title()


func _enter_boot_flow() -> void:
	if _runtime_shell == null:
		return

	_set_state(RuntimeState.BOOT)
	request_title()


func _build_stage_registry() -> void:
	_stage_registry.clear()
	_stage_order.clear()

	for resource_path in STAGE_REGISTRY_PATHS:
		var definition := load(resource_path) as StageDefinition
		if definition == null:
			push_error("GameFlow failed to load stage definition at '%s'." % resource_path)
			continue

		if definition.stage_id.is_empty():
			push_error("Stage definition at '%s' is missing a stage_id." % resource_path)
			continue

		if _stage_registry.has(definition.stage_id):
			push_error("Duplicate stage id '%s' in GameFlow registry." % definition.stage_id)
			continue

		_stage_registry[definition.stage_id] = definition
		_stage_order.append(definition.stage_id)


func _apply_stage_clear_progression(stage_definition: StageDefinition) -> Dictionary:
	var result := {
		"progression_saved": false,
		"reward_weapon_id": StringName(),
		"reward_weapon_name": "",
	}
	if stage_definition == null:
		return result

	var progression := _get_progression()
	if progression == null:
		return result

	var progression_changed := false
	if progression.has_method("mark_stage_cleared"):
		progression_changed = progression.mark_stage_cleared(stage_definition.stage_id) or progression_changed

	if not stage_definition.boss_id.is_empty() and progression.has_method("mark_boss_defeated"):
		var reward_weapon_id := stage_definition.weapon_reward_id
		var boss_reward_changed := bool(progression.mark_boss_defeated(stage_definition.boss_id, reward_weapon_id))
		progression_changed = boss_reward_changed or progression_changed
		if boss_reward_changed and not reward_weapon_id.is_empty():
			result["reward_weapon_id"] = reward_weapon_id
			result["reward_weapon_name"] = WEAPON_CATALOG_SCRIPT.get_weapon_display_name(reward_weapon_id)

	if stage_definition.stage_id == INTRO_STAGE_ID:
		if progression.has_method("mark_intro_cleared"):
			progression_changed = progression.mark_intro_cleared() or progression_changed
		if progression.has_method("unlock_dash"):
			progression_changed = progression.unlock_dash() or progression_changed

	if progression_changed:
		var save_manager := get_node_or_null("/root/SaveManager")
		if save_manager != null and save_manager.has_method("save_game"):
			save_manager.save_game(&"stage_clear")

	result["progression_saved"] = progression_changed
	return result


func _set_state(new_state: int) -> void:
	if current_state == new_state:
		return

	var previous_state := current_state
	current_state = new_state
	state_changed.emit(previous_state, current_state)


func _get_progression() -> Node:
	return get_node_or_null("/root/Progression")

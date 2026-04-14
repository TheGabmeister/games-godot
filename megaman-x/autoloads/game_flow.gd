extends Node

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
const STAGE_REGISTRY_PATHS := [
	"res://data/stages/test_stage.tres",
]

signal state_changed(previous_state: int, new_state: int)
signal stage_changed(stage_id: StringName)
signal cutscene_started(stage_id: StringName, cutscene_id: StringName)
signal cutscene_finished(stage_id: StringName, cutscene_id: StringName)
signal stage_clear_started(stage_id: StringName)

var current_state: int = RuntimeState.BOOT
var current_stage_id: StringName = &""

var _runtime_shell: Node = null
var _stage_registry: Dictionary = {}


func _ready() -> void:
	_build_stage_registry()


func register_runtime_shell(runtime_shell: Node) -> void:
	_runtime_shell = runtime_shell
	call_deferred("_enter_boot_flow")


func get_registered_stage(stage_id: StringName) -> StageDefinition:
	return _stage_registry.get(stage_id) as StageDefinition


func get_registered_stage_ids() -> Array[StringName]:
	var stage_ids: Array[StringName] = []
	for stage_id in _stage_registry.keys():
		stage_ids.append(stage_id as StringName)

	return stage_ids


func request_title() -> void:
	current_stage_id = &""
	_set_state(RuntimeState.TITLE)

	if _runtime_shell != null and _runtime_shell.has_method("show_title_screen"):
		_runtime_shell.show_title_screen(TITLE_SCREEN_SCENE_PATH)


func start_new_game() -> void:
	var progression := get_node_or_null("/root/Progression")
	if progression != null and progression.has_method("reset_for_new_game"):
		progression.reset_for_new_game()
	request_title()


func continue_from_save() -> bool:
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager == null or not save_manager.has_method("load_game"):
		return false

	var loaded := bool(save_manager.load_game())
	if loaded:
		request_title()
	return loaded


func request_stage(stage_id: StringName) -> void:
	var stage_definition := get_registered_stage(stage_id)
	if stage_definition == null:
		push_error("GameFlow missing stage definition for '%s'." % stage_id)
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
	current_stage_id = stage_id
	_set_state(RuntimeState.STAGE_CLEAR)

	var overlay_payload := payload.duplicate(true)
	overlay_payload["stage_id"] = stage_id
	overlay_payload["display_name"] = stage_definition.display_name if stage_definition != null else String(stage_id)

	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null and audio_manager.has_method("play_sfx"):
		audio_manager.play_sfx(&"stage_clear_fanfare")

	if _runtime_shell != null and _runtime_shell.has_method("show_stage_clear_overlay"):
		_runtime_shell.show_stage_clear_overlay(overlay_payload)

	stage_clear_started.emit(current_stage_id)


func _enter_boot_flow() -> void:
	if _runtime_shell == null:
		return

	_set_state(RuntimeState.BOOT)
	request_title()


func _build_stage_registry() -> void:
	_stage_registry.clear()

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


func _set_state(new_state: int) -> void:
	if current_state == new_state:
		return

	var previous_state := current_state
	current_state = new_state
	state_changed.emit(previous_state, current_state)

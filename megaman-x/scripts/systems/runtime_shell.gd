extends Node

const GAMEPLAY_HUD_SCENE_PATH := "res://scenes/ui/GameplayHUD.tscn"

@onready var world_root: Node = $WorldRoot
@onready var ui_root: CanvasLayer = $UIRoot
@onready var overlay_root: CanvasLayer = $OverlayRoot

var _active_stage: Node = null
var _active_hud: Control = null


func _ready() -> void:
	GameFlow.register_runtime_shell(self)


func show_title_screen(scene_path: String) -> void:
	_clear_branch(world_root)
	_clear_branch(ui_root)
	_clear_branch(overlay_root)

	var packed_scene := load(scene_path) as PackedScene
	if packed_scene == null:
		push_error("RuntimeShell failed to load title scene at '%s'." % scene_path)
		return

	ui_root.add_child(packed_scene.instantiate())


func load_stage(stage_definition: StageDefinition) -> void:
	if stage_definition == null or not stage_definition.is_valid():
		push_error("RuntimeShell received an invalid stage definition.")
		return

	_clear_branch(overlay_root)
	_clear_branch(ui_root)
	_clear_branch(world_root)

	var packed_scene := load(stage_definition.scene_path) as PackedScene
	if packed_scene == null:
		push_error("RuntimeShell failed to load stage scene at '%s'." % stage_definition.scene_path)
		return

	_active_stage = packed_scene.instantiate()
	_active_stage.name = String(stage_definition.stage_id)
	world_root.add_child(_active_stage)
	_install_gameplay_hud()


func get_active_stage() -> Node:
	return _active_stage


func get_active_hud() -> Control:
	return _active_hud


func _clear_branch(branch: Node) -> void:
	for child in branch.get_children():
		branch.remove_child(child)
		child.queue_free()

	if branch == world_root:
		_active_stage = null
	elif branch == ui_root:
		_active_hud = null


func _install_gameplay_hud() -> void:
	var hud_scene := load(GAMEPLAY_HUD_SCENE_PATH) as PackedScene
	if hud_scene == null:
		push_error("RuntimeShell failed to load GameplayHUD at '%s'." % GAMEPLAY_HUD_SCENE_PATH)
		return

	_active_hud = hud_scene.instantiate() as Control
	ui_root.add_child(_active_hud)

	var player := _resolve_stage_player(_active_stage)
	if player != null and _active_hud.has_method("bind_player"):
		_active_hud.bind_player(player)


func _resolve_stage_player(stage: Node) -> Node:
	if stage == null:
		return null

	if stage.has_method("get_primary_player"):
		return stage.get_primary_player()

	return stage.get_node_or_null("Player")

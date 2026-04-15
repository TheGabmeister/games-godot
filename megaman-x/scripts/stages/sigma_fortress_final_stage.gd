extends Node2D

const DEFAULT_BOSS_SEQUENCE: Array[StringName] = [
	&"velguarder",
	&"sigma_first_form",
	&"sigma_wolf_form",
]
const BOSS_DISPLAY_NAMES := {
	&"velguarder": "Velguarder",
	&"sigma_first_form": "Sigma First Form",
	&"sigma_wolf_form": "Sigma Wolf Form",
}
const BOSS_TEXTURES := {
	&"velguarder": preload("res://assets/placeholders/bosses/velguarder_96x96.svg"),
	&"sigma_first_form": preload("res://assets/placeholders/bosses/sigma_first_form_96x96.svg"),
	&"sigma_wolf_form": preload("res://assets/placeholders/bosses/sigma_wolf_form_96x96.svg"),
}

var _stage_definition: StageDefinition = null
var _boss_sequence: Array[StringName] = DEFAULT_BOSS_SEQUENCE.duplicate()
var _completed_boss_ids: Array[StringName] = []
var _active_boss_index := -1
var _sequence_started := false
var _player_can_resolve_boss := false

@onready var player: Node = $Player
@onready var follow_camera: Camera2D = $Camera2D
@onready var stage_controller: StageController = $StageController
@onready var boss_gate_trigger: Area2D = $BossGateTrigger
@onready var resolve_area: Area2D = $ResolveArea
@onready var boss_barrier_left: BossArenaBarrier = $BossBarrierLeft
@onready var boss_barrier_right: BossArenaBarrier = $BossBarrierRight
@onready var stage_label: Label = $CanvasLayer/Panel/VBoxContainer/StageLabel
@onready var body_label: Label = $CanvasLayer/Panel/VBoxContainer/BodyLabel
@onready var slot_sprites: Array[Sprite2D] = [
	$BossSlots/BossSlotOne/Sprite2D,
	$BossSlots/BossSlotTwo/Sprite2D,
	$BossSlots/BossSlotThree/Sprite2D,
]
@onready var slot_labels: Array[Label] = [
	$BossSlots/BossSlotOne/Label,
	$BossSlots/BossSlotTwo/Label,
	$BossSlots/BossSlotThree/Label,
]


func _ready() -> void:
	if player != null and player.has_method("set_dash_unlocked"):
		player.set_dash_unlocked(bool(Progression.dash_unlocked))
	if follow_camera != null and player != null and player.has_method("get_camera_anchor"):
		follow_camera.set_target(player.get_camera_anchor())
	if boss_gate_trigger != null:
		boss_gate_trigger.body_entered.connect(_on_boss_gate_body_entered)
	if resolve_area != null:
		resolve_area.body_entered.connect(_on_resolve_area_body_entered)
		resolve_area.body_exited.connect(_on_resolve_area_body_exited)
	_set_barriers_locked(false)
	_refresh_ui()


func configure_stage_definition(stage_definition: StageDefinition) -> void:
	_stage_definition = stage_definition
	if stage_controller != null:
		stage_controller.stage_id = stage_definition.stage_id
	_boss_sequence = stage_definition.ordered_boss_ids.duplicate() if not stage_definition.ordered_boss_ids.is_empty() else DEFAULT_BOSS_SEQUENCE.duplicate()
	if is_inside_tree():
		_refresh_ui()


func get_primary_player() -> Node:
	return player


func has_sequence_started() -> bool:
	return _sequence_started


func get_active_boss_id() -> StringName:
	if _active_boss_index < 0 or _active_boss_index >= _boss_sequence.size():
		return &""

	return _boss_sequence[_active_boss_index]


func get_completed_boss_ids() -> Array[StringName]:
	return _completed_boss_ids.duplicate()


func start_final_sequence_for_test() -> bool:
	return _start_final_sequence()


func resolve_active_boss_for_test() -> bool:
	return _resolve_active_boss(&"test")


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"interact"):
		return
	if not _player_can_resolve_boss:
		return

	var viewport := get_viewport()
	if viewport != null:
		viewport.set_input_as_handled()
	_resolve_active_boss(&"interact")


func _start_final_sequence() -> bool:
	if _sequence_started or _boss_sequence.is_empty():
		return false

	_sequence_started = true
	_active_boss_index = 0
	_set_barriers_locked(true)
	_refresh_ui()
	return true


func _resolve_active_boss(source_id: StringName) -> bool:
	if not _sequence_started:
		return false

	var active_boss_id := get_active_boss_id()
	if active_boss_id.is_empty():
		return false

	_completed_boss_ids.append(active_boss_id)
	_active_boss_index += 1
	if _active_boss_index >= _boss_sequence.size():
		_active_boss_index = _boss_sequence.size()
		_sequence_started = false
		_player_can_resolve_boss = false
		_set_barriers_locked(false)
		_refresh_ui()
		if stage_controller != null:
			stage_controller.begin_stage_clear(source_id if not source_id.is_empty() else &"final_sigma")
		return true

	_refresh_ui()
	return true


func _set_barriers_locked(locked: bool) -> void:
	if boss_barrier_left != null:
		boss_barrier_left.set_locked(locked)
	if boss_barrier_right != null:
		boss_barrier_right.set_locked(locked)


func _refresh_ui() -> void:
	var display_name := "Sigma Fortress 4"
	if _stage_definition != null and not _stage_definition.display_name.is_empty():
		display_name = _stage_definition.display_name
	stage_label.text = display_name

	var detail_lines := [
		"Final Sigma placeholder slice.",
		"Dash unlocked: %s" % ("yes" if Progression.dash_unlocked else "no"),
	]
	if _completed_boss_ids.size() >= _boss_sequence.size():
		detail_lines.append("Sequence complete. Ending flow should now be active.")
	elif not _sequence_started:
		detail_lines.append("Enter the boss gate to start the final fortress sequence.")
	else:
		detail_lines.append("Active target: %s" % _get_boss_display_name(get_active_boss_id()))
		detail_lines.append("Press interact inside the resolve zone to advance the placeholder encounter.")

	var encounter_lines := PackedStringArray()
	for index in range(_boss_sequence.size()):
		var boss_id := _boss_sequence[index]
		var status := "PENDING"
		if index < _completed_boss_ids.size():
			status = "CLEAR"
		elif index == _active_boss_index and _sequence_started:
			status = "ACTIVE"
		encounter_lines.append("%d. %s [%s]" % [index + 1, _get_boss_display_name(boss_id), status])
	if not encounter_lines.is_empty():
		detail_lines.append("Encounter order:")
		for line in encounter_lines:
			detail_lines.append(line)

	body_label.text = "\n".join(detail_lines)
	_refresh_boss_slots()


func _refresh_boss_slots() -> void:
	for index in range(slot_sprites.size()):
		var sprite := slot_sprites[index]
		var label := slot_labels[index]
		var has_boss := index < _boss_sequence.size()
		if sprite == null or label == null:
			continue
		if not has_boss:
			sprite.visible = false
			label.visible = false
			continue

		var boss_id := _boss_sequence[index]
		sprite.visible = true
		label.visible = true
		sprite.texture = BOSS_TEXTURES.get(boss_id, null)
		label.text = _get_boss_display_name(boss_id)
		if index < _completed_boss_ids.size():
			sprite.modulate = Color(0.48, 0.96, 0.72, 0.75)
			label.modulate = Color(0.78, 1, 0.86, 1)
		elif index == _active_boss_index and _sequence_started:
			sprite.modulate = Color(1, 1, 1, 1)
			label.modulate = Color(1, 0.96, 0.8, 1)
		else:
			sprite.modulate = Color(0.56, 0.64, 0.74, 0.58)
			label.modulate = Color(0.68, 0.76, 0.84, 1)


func _get_boss_display_name(boss_id: StringName) -> String:
	if BOSS_DISPLAY_NAMES.has(boss_id):
		return String(BOSS_DISPLAY_NAMES[boss_id])
	return String(boss_id).replace("_", " ").capitalize()


func _on_boss_gate_body_entered(body: Node) -> void:
	if player != null and body != player:
		return
	_start_final_sequence()


func _on_resolve_area_body_entered(body: Node) -> void:
	if player != null and body != player:
		return
	_player_can_resolve_boss = true
	_refresh_ui()


func _on_resolve_area_body_exited(body: Node) -> void:
	if player != null and body != player:
		return
	_player_can_resolve_boss = false
	_refresh_ui()

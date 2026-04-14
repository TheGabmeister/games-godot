extends Node
class_name BossEncounterController

signal encounter_started(boss_id: StringName, display_name: String)
signal encounter_ended(boss_id: StringName, reason: StringName)
signal boss_health_changed(current_health: int, max_health: int)
signal arena_lock_changed(is_locked: bool)

@export var player_path: NodePath
@export var entry_trigger_path: NodePath
@export var boss_path: NodePath
@export var barrier_paths: Array[NodePath] = []
@export var boss_id: StringName = &"test_boss"
@export var boss_display_name := "Boss Target"

var encounter_active := false
var encounter_completed := false

var _arena_locked := false

@onready var player: Node = get_node_or_null(player_path)
@onready var entry_trigger: Area2D = get_node_or_null(entry_trigger_path) as Area2D
@onready var boss: Node = get_node_or_null(boss_path)

var _boss_health: Node = null
var _barriers: Array[Node] = []


func _ready() -> void:
	add_to_group(&"stage_resettable")
	for barrier_path in barrier_paths:
		var barrier := get_node_or_null(barrier_path)
		if barrier != null:
			_barriers.append(barrier)

	if entry_trigger != null:
		entry_trigger.body_entered.connect(_on_entry_trigger_body_entered)

	_boss_health = _resolve_boss_health()
	if _boss_health != null:
		_boss_health.connect("health_changed", _on_boss_health_changed)
		_boss_health.connect("died", _on_boss_died)
		if _boss_health.has_signal("revived"):
			_boss_health.connect("revived", _on_boss_revived)

	_set_arena_locked(false)
	_emit_boss_health()


func is_encounter_active() -> bool:
	return encounter_active


func has_encounter_completed() -> bool:
	return encounter_completed


func is_arena_locked() -> bool:
	return _arena_locked


func get_boss_display_name() -> String:
	if not boss_display_name.is_empty():
		return boss_display_name
	if boss != null and boss.get("dummy_name") != null:
		return str(boss.get("dummy_name"))
	return "Boss Target"


func get_boss_current_health() -> int:
	return int(_boss_health.get("current_health")) if _boss_health != null else 0


func get_boss_max_health() -> int:
	return int(_boss_health.get("max_health")) if _boss_health != null else 0


func start_encounter() -> bool:
	if encounter_active or encounter_completed:
		return false
	if _boss_health == null or bool(_boss_health.get("is_dead")):
		return false

	encounter_active = true
	_set_arena_locked(true)
	_emit_boss_health()
	encounter_started.emit(boss_id, get_boss_display_name())
	return true


func reset_for_stage_retry() -> void:
	var changed := encounter_active or encounter_completed or _arena_locked
	encounter_active = false
	encounter_completed = false
	_set_arena_locked(false)
	if changed:
		encounter_ended.emit(boss_id, &"reset")


func _resolve_boss_health() -> Node:
	if boss == null:
		return null
	if boss.has_method("get_health_component"):
		return boss.get_health_component()
	return boss.get_node_or_null("HealthComponent")


func _set_arena_locked(is_locked: bool) -> void:
	if _arena_locked == is_locked:
		return

	_arena_locked = is_locked
	for barrier in _barriers:
		if barrier != null and barrier.has_method("set_locked"):
			barrier.set_locked(_arena_locked)
	arena_lock_changed.emit(_arena_locked)


func _emit_boss_health() -> void:
	boss_health_changed.emit(get_boss_current_health(), get_boss_max_health())


func _on_entry_trigger_body_entered(body: Node) -> void:
	if body == null:
		return
	if player != null and body != player:
		return
	if player == null and not body.has_method("get_health_component"):
		return

	start_encounter()


func _on_boss_health_changed(current_health: int, max_health: int) -> void:
	boss_health_changed.emit(current_health, max_health)


func _on_boss_died() -> void:
	if encounter_completed:
		return

	encounter_active = false
	encounter_completed = true
	_set_arena_locked(false)
	encounter_ended.emit(boss_id, &"defeated")


func _on_boss_revived() -> void:
	_emit_boss_health()

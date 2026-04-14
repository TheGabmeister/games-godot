extends Node
class_name EnemyBrain

signal awake_changed(is_awake: bool)
signal state_changed(previous_state: StringName, new_state: StringName)

@export var idle_state_path: NodePath = NodePath("IdleState")
@export var patrol_state_path: NodePath = NodePath("PatrolState")
@export var dead_state_path: NodePath = NodePath("DeadState")

@onready var _enemy: Node = get_parent()
@onready var _idle_state: Node = get_node_or_null(idle_state_path)
@onready var _patrol_state: Node = get_node_or_null(patrol_state_path)
@onready var _dead_state: Node = get_node_or_null(dead_state_path)

var _current_state: Node = null
var _is_awake := false


func _ready() -> void:
	_transition_to(_idle_state)


func _physics_process(delta: float) -> void:
	if _current_state != null:
		_current_state.call("physics_update", self, delta)


func get_enemy() -> Node:
	return _enemy


func is_awake() -> bool:
	return _is_awake


func get_state_name() -> StringName:
	if _current_state == null:
		return &"NONE"

	return _current_state.call("get_state_name")


func wake() -> void:
	if _dead_state == _current_state:
		return

	if not _is_awake:
		_is_awake = true
		awake_changed.emit(true)

	_transition_to(_patrol_state)


func sleep() -> void:
	if _dead_state == _current_state:
		return

	if _is_awake:
		_is_awake = false
		awake_changed.emit(false)

	_transition_to(_idle_state)


func notify_enemy_defeated() -> void:
	if _is_awake:
		_is_awake = false
		awake_changed.emit(false)

	_transition_to(_dead_state)


func reset_brain() -> void:
	_is_awake = false
	_transition_to(_idle_state)


func _transition_to(next_state: Node) -> void:
	if next_state == null or _current_state == next_state:
		return

	var previous_name: StringName = &"NONE"
	if _current_state != null:
		previous_name = _current_state.call("get_state_name")
		_current_state.call("exit", self)

	_current_state = next_state
	_current_state.call("enter", self)
	state_changed.emit(previous_name, _current_state.call("get_state_name"))

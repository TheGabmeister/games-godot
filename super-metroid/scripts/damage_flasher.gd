class_name DamageFlasher
extends Node

@export var flash_interval: float = 0.08
@export var target_path: NodePath

var _target: CanvasItem
var _active: bool = false
var _timer: float = 0.0


func _ready() -> void:
	if target_path:
		_target = get_node(target_path) as CanvasItem


func start(target: CanvasItem = null) -> void:
	if target:
		_target = target
	_active = true
	_timer = 0.0


func stop() -> void:
	_active = false
	if _target:
		_target.modulate.a = 1.0


func is_active() -> bool:
	return _active


func _process(delta: float) -> void:
	if not _active or not _target:
		return
	_timer += delta
	if fmod(_timer, flash_interval * 2.0) < flash_interval:
		_target.modulate.a = 0.3
	else:
		_target.modulate.a = 1.0

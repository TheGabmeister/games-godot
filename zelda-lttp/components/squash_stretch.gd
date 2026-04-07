class_name SquashStretch extends Node

## Applies squash/stretch animation to a target Node2D's scale property.
## Attach as a child of the entity. Set target_node to the visual node (e.g., PlayerBody).

@export var target_path: NodePath

var _target: Node2D = null
var _tween: Tween = null


func _ready() -> void:
	if target_path:
		_target = get_node_or_null(target_path) as Node2D


func squash(scale_x: float = 0.8, scale_y: float = 1.2, duration: float = 0.1) -> void:
	_play(Vector2(scale_x, scale_y), duration)


func stretch(scale_x: float = 1.2, scale_y: float = 0.8, duration: float = 0.1) -> void:
	_play(Vector2(scale_x, scale_y), duration)


func land_squash(duration: float = 0.15) -> void:
	_play(Vector2(1.3, 0.6), duration)


func attack_squash(duration: float = 0.1) -> void:
	if not _target:
		return
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_target, "scale", Vector2(0.8, 1.2), duration * 0.4)
	_tween.tween_property(_target, "scale", Vector2(1.2, 0.8), duration * 0.3)
	_tween.tween_property(_target, "scale", Vector2.ONE, duration * 0.3)


func _play(target_scale: Vector2, duration: float) -> void:
	if not _target:
		return
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_target, "scale", target_scale, duration * 0.3)
	_tween.tween_property(_target, "scale", Vector2.ONE, duration * 0.7).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)

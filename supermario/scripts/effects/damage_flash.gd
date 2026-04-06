extends Node

var _effects: Resource

var _flash_timer: float = 0.0
var _target: CanvasItem


func _ready() -> void:
	_target = get_parent() as CanvasItem
	_effects = (_target as CharacterBody2D).effects if _target is CharacterBody2D else preload("res://resources/config/effects_default.tres")
	set_process(false)
	EventBus.player_damaged.connect(_on_player_damaged)


func _on_player_damaged() -> void:
	_flash_timer = _effects.damage_flash_duration
	set_process(true)
	if _target:
		_target.modulate = Color(1.0, 0.4, 0.4)


func _process(delta: float) -> void:
	_flash_timer -= delta
	if _flash_timer <= 0.0:
		set_process(false)
		if _target:
			_target.modulate = Color(1.0, 1.0, 1.0, _target.modulate.a)

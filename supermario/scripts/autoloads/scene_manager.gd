extends Node

const _timing := preload("res://resources/config/level_timing_default.tres")

var _is_transitioning: bool = false

@onready var _overlay: CanvasLayer = CanvasLayer.new()
@onready var _fade_rect: ColorRect = ColorRect.new()
@onready var _intro_label: Label = Label.new()


func _ready() -> void:
	_overlay.layer = 100
	add_child(_overlay)

	_fade_rect.color = Color.BLACK
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.modulate.a = 0.0
	_overlay.add_child(_fade_rect)

	_intro_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_intro_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_intro_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_intro_label.visible = false
	_intro_label.modulate = Color.WHITE
	_overlay.add_child(_intro_label)


func change_scene(path: String) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	await _fade_out()
	get_tree().change_scene_to_file(path)
	await _fade_in()
	_is_transitioning = false


func reload_current_scene() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	await _fade_out()
	get_tree().reload_current_scene()
	await _fade_in()
	_is_transitioning = false


func show_level_intro(world: int, level: int, lives: int) -> void:
	_fade_rect.modulate.a = 1.0
	_intro_label.text = "WORLD %d-%d\n\nMARIO x %d" % [world, level, lives]
	_intro_label.visible = true

	await get_tree().create_timer(_timing.level_intro_duration).timeout

	_intro_label.visible = false
	await _fade_in()


func _fade_out() -> void:
	var tween := create_tween()
	tween.tween_property(_fade_rect, "modulate:a", 1.0, _timing.fade_duration)
	await tween.finished


func _fade_in() -> void:
	var tween := create_tween()
	tween.tween_property(_fade_rect, "modulate:a", 0.0, _timing.fade_duration)
	await tween.finished

extends "res://scripts/objects/block_base.gd"

const CoinScene := preload("res://scenes/objects/coin.tscn")
const MushroomScene := preload("res://scenes/objects/mushroom.tscn")
const FireFlowerScene := preload("res://scenes/objects/fire_flower.tscn")
const StarmanScene := preload("res://scenes/objects/starman.tscn")

@export var contents: StringName = &"coin"
@export var coin_sound: AudioStream

var _used: bool = false
var _pulse_time: float = 0.0


func _process(delta: float) -> void:
	super._process(delta)
	_pulse_time += delta
	queue_redraw()


func _draw() -> void:
	var y_off: float = _bump_offset
	if _used:
		draw_rect(Rect2(-8, -16 + y_off, 16, 16), Palette.BLOCK_BROWN)
		draw_rect(Rect2(-8, -16 + y_off, 16, 2), Palette.BLOCK_BROWN.darkened(0.3))
		draw_rect(Rect2(-8, -2 + y_off, 16, 2), Palette.BLOCK_BROWN.darkened(0.3))
		draw_rect(Rect2(-8, -16 + y_off, 2, 16), Palette.BLOCK_BROWN.darkened(0.3))
		draw_rect(Rect2(6, -16 + y_off, 2, 16), Palette.BLOCK_BROWN.darkened(0.3))
	else:
		var pulse: float = bump_config.pulse_min + bump_config.pulse_range * sin(_pulse_time * TAU * bump_config.pulse_frequency)
		var base: Color = Palette.QUESTION_YELLOW * pulse
		base.a = 1.0
		draw_rect(Rect2(-8, -16 + y_off, 16, 16), base)
		draw_rect(Rect2(-8, -16 + y_off, 16, 2), Palette.QUESTION_DARK)
		draw_rect(Rect2(-8, -2 + y_off, 16, 2), Palette.QUESTION_DARK)
		draw_rect(Rect2(-8, -16 + y_off, 2, 16), Palette.QUESTION_DARK)
		draw_rect(Rect2(6, -16 + y_off, 2, 16), Palette.QUESTION_DARK)
		draw_rect(Rect2(-3, -13 + y_off, 6, 2), Palette.QUESTION_DARK)
		draw_rect(Rect2(2, -11 + y_off, 2, 3), Palette.QUESTION_DARK)
		draw_rect(Rect2(-1, -8 + y_off, 2, 2), Palette.QUESTION_DARK)
		draw_rect(Rect2(-1, -4 + y_off, 2, 2), Palette.QUESTION_DARK)


func bump_from_below() -> void:
	if _used:
		return
	_used = true
	start_bump()
	play_bump_sound()
	EventBus.block_bumped.emit(global_position)
	_spawn_contents()


func _spawn_contents() -> void:
	var spawn_pos: Vector2 = global_position + Vector2(0, -16)
	match contents:
		&"coin":
			_play_sound(coin_sound)
			GameManager.add_coin(spawn_pos)
			EventBus.item_spawned.emit(&"coin", spawn_pos)
		&"mushroom":
			var item_type: StringName = &"mushroom"
			if GameManager.current_power_state != GameManager.PowerState.SMALL:
				item_type = &"fire_flower"
			_spawn_item(item_type, spawn_pos)
		&"fire_flower":
			_spawn_item(&"fire_flower", spawn_pos)
		&"starman":
			_spawn_item(&"starman", spawn_pos)
		_:
			push_warning("Unknown question block contents: %s" % contents)


func _spawn_item(item_type: StringName, spawn_pos: Vector2) -> void:
	var scene: PackedScene
	match item_type:
		&"mushroom":
			scene = MushroomScene
		&"fire_flower":
			scene = FireFlowerScene
		&"starman":
			scene = StarmanScene
	if scene == null:
		return
	var item := scene.instantiate() as Node2D
	get_parent().add_child(item)
	item.global_position = spawn_pos
	EventBus.item_spawned.emit(item_type, spawn_pos)

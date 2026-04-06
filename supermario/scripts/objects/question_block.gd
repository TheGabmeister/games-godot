extends StaticBody2D

const P := preload("res://scripts/color_palette.gd")
const CoinScene := preload("res://scenes/objects/coin.tscn")
const MushroomScene := preload("res://scenes/objects/mushroom.tscn")
const FireFlowerScene := preload("res://scenes/objects/fire_flower.tscn")

@export var contents: StringName = &"coin"
@export var bump_config: Resource  # BlockBumpConfig

var _used: bool = false
var _bump_offset: float = 0.0
var _bump_time: float = 0.0
var _bumping: bool = false
var _pulse_time: float = 0.0


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0


func _process(delta: float) -> void:
	_pulse_time += delta

	if _bumping:
		_bump_time += delta
		var t: float = _bump_time / bump_config.bump_duration
		if t >= 1.0:
			_bump_offset = 0.0
			_bumping = false
		else:
			_bump_offset = -bump_config.bump_amplitude * sin(t * PI)

	queue_redraw()


func _draw() -> void:
	var y_off: float = _bump_offset
	if _used:
		draw_rect(Rect2(-8, -16 + y_off, 16, 16), P.BLOCK_BROWN)
		draw_rect(Rect2(-8, -16 + y_off, 16, 2), P.BLOCK_BROWN.darkened(0.3))
		draw_rect(Rect2(-8, -2 + y_off, 16, 2), P.BLOCK_BROWN.darkened(0.3))
		draw_rect(Rect2(-8, -16 + y_off, 2, 16), P.BLOCK_BROWN.darkened(0.3))
		draw_rect(Rect2(6, -16 + y_off, 2, 16), P.BLOCK_BROWN.darkened(0.3))
	else:
		var pulse: float = bump_config.pulse_min + bump_config.pulse_range * sin(_pulse_time * TAU * bump_config.pulse_frequency)
		var base: Color = P.QUESTION_YELLOW * pulse
		base.a = 1.0
		draw_rect(Rect2(-8, -16 + y_off, 16, 16), base)
		draw_rect(Rect2(-8, -16 + y_off, 16, 2), P.QUESTION_DARK)
		draw_rect(Rect2(-8, -2 + y_off, 16, 2), P.QUESTION_DARK)
		draw_rect(Rect2(-8, -16 + y_off, 2, 16), P.QUESTION_DARK)
		draw_rect(Rect2(6, -16 + y_off, 2, 16), P.QUESTION_DARK)
		draw_rect(Rect2(-3, -13 + y_off, 6, 2), P.QUESTION_DARK)
		draw_rect(Rect2(2, -11 + y_off, 2, 3), P.QUESTION_DARK)
		draw_rect(Rect2(-1, -8 + y_off, 2, 2), P.QUESTION_DARK)
		draw_rect(Rect2(-1, -4 + y_off, 2, 2), P.QUESTION_DARK)


func bump_from_below() -> void:
	if _used:
		return
	_used = true
	_bumping = true
	_bump_time = 0.0
	EventBus.block_bumped.emit(global_position)
	_spawn_contents()


func _spawn_contents() -> void:
	var spawn_pos: Vector2 = global_position + Vector2(0, -16)
	match contents:
		&"coin":
			GameManager.add_coin(spawn_pos)
			EventBus.item_spawned.emit(&"coin", spawn_pos)
		&"mushroom":
			var item_type: StringName = &"mushroom"
			if GameManager.current_power_state != GameManager.PowerState.SMALL:
				item_type = &"fire_flower"
			_spawn_item(item_type, spawn_pos)
		&"fire_flower":
			_spawn_item(&"fire_flower", spawn_pos)
		_:
			push_warning("Unknown question block contents: %s" % contents)


func _spawn_item(item_type: StringName, spawn_pos: Vector2) -> void:
	var scene: PackedScene
	match item_type:
		&"mushroom":
			scene = MushroomScene
		&"fire_flower":
			scene = FireFlowerScene
	if scene == null:
		return
	var item := scene.instantiate() as Node2D
	get_parent().add_child(item)
	item.global_position = spawn_pos
	EventBus.item_spawned.emit(item_type, spawn_pos)

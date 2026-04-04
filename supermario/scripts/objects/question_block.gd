extends StaticBody2D

const P := preload("res://scripts/color_palette.gd")
const CoinScene := preload("res://scenes/objects/coin.tscn")
const MushroomScene := preload("res://scenes/objects/mushroom.tscn")
const FireFlowerScene := preload("res://scenes/objects/fire_flower.tscn")

@export var contents: StringName = &"coin"

var _used: bool = false
var _bump_offset: float = 0.0
var _bump_time: float = 0.0
var _bumping: bool = false
var _pulse_time: float = 0.0

@onready var bump_detector: Area2D = $BumpDetector


func _ready() -> void:
	collision_layer = 1  # Terrain
	collision_mask = 0
	bump_detector.body_entered.connect(_on_bump_detected)


func _process(delta: float) -> void:
	_pulse_time += delta

	if _bumping:
		_bump_time += delta
		var t: float = _bump_time / 0.15
		if t >= 1.0:
			_bump_offset = 0.0
			_bumping = false
		else:
			# Triangle wave: 0 → -4 → 0
			_bump_offset = -4.0 * sin(t * PI)

	queue_redraw()


func _draw() -> void:
	var y_off: float = _bump_offset
	if _used:
		# Empty block appearance
		draw_rect(Rect2(-8, -16 + y_off, 16, 16), P.BLOCK_BROWN)
		draw_rect(Rect2(-8, -16 + y_off, 16, 2), P.BLOCK_BROWN.darkened(0.3))
		draw_rect(Rect2(-8, -2 + y_off, 16, 2), P.BLOCK_BROWN.darkened(0.3))
		draw_rect(Rect2(-8, -16 + y_off, 2, 16), P.BLOCK_BROWN.darkened(0.3))
		draw_rect(Rect2(6, -16 + y_off, 2, 16), P.BLOCK_BROWN.darkened(0.3))
	else:
		# Active ? block with pulsing glow
		var pulse: float = 0.85 + 0.15 * sin(_pulse_time * TAU * 0.8)
		var base: Color = P.QUESTION_YELLOW * pulse
		base.a = 1.0
		draw_rect(Rect2(-8, -16 + y_off, 16, 16), base)
		# Dark border
		draw_rect(Rect2(-8, -16 + y_off, 16, 2), P.QUESTION_DARK)
		draw_rect(Rect2(-8, -2 + y_off, 16, 2), P.QUESTION_DARK)
		draw_rect(Rect2(-8, -16 + y_off, 2, 16), P.QUESTION_DARK)
		draw_rect(Rect2(6, -16 + y_off, 2, 16), P.QUESTION_DARK)
		# "?" glyph
		draw_rect(Rect2(-3, -13 + y_off, 6, 2), P.QUESTION_DARK)
		draw_rect(Rect2(2, -11 + y_off, 2, 3), P.QUESTION_DARK)
		draw_rect(Rect2(-1, -8 + y_off, 2, 2), P.QUESTION_DARK)
		draw_rect(Rect2(-1, -4 + y_off, 2, 2), P.QUESTION_DARK)


func _on_bump_detected(body: Node2D) -> void:
	if _used:
		return
	if not body is CharacterBody2D:
		return
	# Only trigger if body is moving upward
	if body.velocity.y >= 0.0:
		return
	_trigger_bump()


func _trigger_bump() -> void:
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


func _spawn_item(item_type: StringName, position: Vector2) -> void:
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
	item.global_position = position
	EventBus.item_spawned.emit(item_type, position)

extends "res://scripts/objects/block_base.gd"

const MushroomScene := preload("res://scenes/objects/mushroom.tscn")

@export var contents: StringName = &"coin"
@export var coin_sound: AudioStream

var _revealed: bool = false

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var trigger_area: Area2D = $TriggerArea


func _ready() -> void:
	super._ready()
	collision_shape.disabled = true
	trigger_area.body_entered.connect(_on_body_entered)


func _draw() -> void:
	if not _revealed:
		return
	var y_off: float = _bump_offset
	draw_rect(Rect2(-8, -16 + y_off, 16, 16), Palette.BLOCK_BROWN)
	draw_rect(Rect2(-8, -16 + y_off, 16, 2), Palette.BLOCK_BROWN.darkened(0.3))
	draw_rect(Rect2(-8, -2 + y_off, 16, 2), Palette.BLOCK_BROWN.darkened(0.3))
	draw_rect(Rect2(-8, -16 + y_off, 2, 16), Palette.BLOCK_BROWN.darkened(0.3))
	draw_rect(Rect2(6, -16 + y_off, 2, 16), Palette.BLOCK_BROWN.darkened(0.3))


func _on_body_entered(body: Node2D) -> void:
	if _revealed:
		return
	if not body.is_in_group("player"):
		return
	if body.velocity.y >= 0.0:
		return
	_reveal_and_bump()


func _reveal_and_bump() -> void:
	_revealed = true
	collision_shape.set_deferred("disabled", false)
	trigger_area.set_deferred("monitoring", false)
	start_bump()
	play_bump_sound()
	EventBus.block_bumped.emit(global_position)
	queue_redraw()
	_spawn_contents()


func _spawn_contents() -> void:
	var spawn_pos: Vector2 = global_position + Vector2(0, -32)
	match contents:
		&"coin":
			_play_sound(coin_sound)
			GameManager.add_coin(spawn_pos)
			EventBus.item_spawned.emit(&"coin", spawn_pos)
		&"1up":
			var item := MushroomScene.instantiate() as Node2D
			get_parent().add_child(item)
			item.global_position = spawn_pos
			EventBus.item_spawned.emit(&"1up", spawn_pos)
		_:
			push_warning("Unknown hidden block contents: %s" % contents)

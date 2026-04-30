extends "res://scripts/objects/block_base.gd"

const SpriteHelper := preload("res://scripts/visuals/sprite_region_helper.gd")
const SHEET := preload("res://sprites/blocks_sheet.png")
const MushroomScene := preload("res://scenes/objects/mushroom.tscn")

@export var contents: StringName = &"coin"
@export var coin_sound: AudioStream

var _revealed: bool = false
var _sprite: Sprite2D

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var trigger_area: Area2D = $TriggerArea


func _ready() -> void:
	super._ready()
	collision_shape.disabled = true
	trigger_area.body_entered.connect(_on_body_entered)
	_sprite = SpriteHelper.ensure_sprite(self, &"Sprite", SHEET)
	_sprite.visible = false
	_update_sprite()


func _process(delta: float) -> void:
	super._process(delta)
	_update_sprite()


func _update_sprite() -> void:
	_sprite.visible = _revealed
	SpriteHelper.set_cell(_sprite, 3, 6, Vector2(-16, -26 + _bump_offset), Vector2(0.8, 0.8))


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
			if item.has_node("Drawer"):
				var drawer := item.get_node("Drawer")
				if drawer.has_method("set_one_up"):
					drawer.set_one_up(true)
			item.global_position = spawn_pos
			EventBus.item_spawned.emit(&"1up", spawn_pos)
		_:
			push_warning("Unknown hidden block contents: %s" % contents)

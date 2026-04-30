extends Area2D

const EmergeHelper := preload("res://scripts/objects/emerge_helper.gd")
const SpriteHelper := preload("res://scripts/visuals/sprite_region_helper.gd")
const SHEET := preload("res://sprites/powerups_sheet.png")

@export var item_config: Resource  # ItemConfig

var _emerge := EmergeHelper.new()
var _collected: bool = false
var _anim_time: float = 0.0
var _sprite: Sprite2D


func _ready() -> void:
	monitoring = false
	body_entered.connect(_on_body_entered)
	_sprite = SpriteHelper.ensure_sprite(self, &"Sprite", SHEET)
	SpriteHelper.set_cell(_sprite, 2, 5, Vector2(-16, -30))


func _process(delta: float) -> void:
	if _collected:
		return

	_anim_time += delta
	SpriteHelper.set_cell(_sprite, 2 + int(_anim_time * 6.0) % 3, 5, Vector2(-16, -30))

	if not _emerge.done:
		global_position.y = _emerge.update(delta, global_position.y, item_config.emerge_duration, item_config.emerge_height)
		if _emerge.done:
			monitoring = true


func _on_body_entered(body: Node) -> void:
	if _collected:
		return
	if body.has_method("power_up"):
		_collected = true
		body.power_up(&"fire_flower", global_position)
		queue_free()

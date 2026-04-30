extends Area2D

const EmergeHelper := preload("res://scripts/objects/emerge_helper.gd")

@export var item_config: Resource  # ItemConfig

var _emerge := EmergeHelper.new()
var _collected: bool = false

@onready var _sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	monitoring = false
	body_entered.connect(_on_body_entered)
	_sprite.play(&"pulse")


func _process(delta: float) -> void:
	if _collected:
		return
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

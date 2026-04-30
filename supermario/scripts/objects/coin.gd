extends Area2D

@export var collect_sound: AudioStream

var _collected: bool = false

@onready var _sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_sprite.play(&"spin")


func _on_body_entered(_body: Node2D) -> void:
	_collect()


func _collect() -> void:
	if _collected:
		return
	_collected = true
	if collect_sound != null:
		EventBus.sfx_requested.emit(collect_sound)
	GameManager.add_coin(global_position)
	queue_free()

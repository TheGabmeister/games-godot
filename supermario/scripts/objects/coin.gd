extends Area2D

const PickupHelper := preload("res://scripts/pickups/pickup_helper.gd")

@export var collect_sound: AudioStream

var _pickup := PickupHelper.new()

@onready var _sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_sprite.play(&"spin")


func _on_body_entered(_body: Node2D) -> void:
	if _pickup.try_collect(self, collect_sound):
		GameManager.add_coin(global_position)

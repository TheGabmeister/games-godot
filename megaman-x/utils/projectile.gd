extends Node2D

@export var _lifetime := 3.0

func _ready():
	await get_tree().create_timer(_lifetime).timeout
	queue_free()

func _on_area_2d_area_entered(_area: Node2D) -> void:
	queue_free()

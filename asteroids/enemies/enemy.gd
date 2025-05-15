extends Node

@export var _score = 100

func _on_area_2d_area_entered(area: Area2D) -> void:
	Bus.enemy_killed.emit(_score)
	pass # Replace with function body.

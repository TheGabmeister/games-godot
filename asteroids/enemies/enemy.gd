extends Node

@export var _score = 100

func _on_area_2d_area_entered(area: Area2D):
	Bus.enemy_killed.emit(_score)
	queue_free()

# This is an abstract base class. Do not attach to any nodes!
class_name EnemyBase
extends Node2D

@export var _score = 100

func _on_area_2d_area_entered(_area: Area2D):
	Bus.enemy_killed.emit(_score)
	queue_free()

# This is an a base class for enemies. Do not spawn this on the level.
# Only inherit from this base
class_name EnemyBase
extends Node2D

@export var _score = 100
@export var _death_sound: AudioStream

func _on_area_2d_area_entered(_area: Area2D):
	Bus.enemy_killed.emit(_score)
	Bus.sfx_play_sound.emit(_death_sound)
	queue_free()

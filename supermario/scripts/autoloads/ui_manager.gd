extends Node

const _game_over_scene := preload("res://scenes/ui/game_over.tscn")


func _ready() -> void:
	add_child(_game_over_scene.instantiate())

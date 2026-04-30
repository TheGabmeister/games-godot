extends Node

const _pause_menu_scene := preload("res://scenes/ui/pause_menu.tscn")
const _game_over_scene := preload("res://scenes/ui/game_over.tscn")
const _level_complete_scene := preload("res://scenes/ui/level_complete.tscn")


func _ready() -> void:
	add_child(_pause_menu_scene.instantiate())
	add_child(_game_over_scene.instantiate())
	add_child(_level_complete_scene.instantiate())

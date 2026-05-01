extends Node2D

@export var player_scene: PackedScene

var player: CharacterBody2D


func _ready() -> void:
	_spawn_player()
	player.died.connect(GameManager.on_player_died)


func _spawn_player() -> void:
	var start := get_node_or_null("PlayerStart") as Marker2D
	player = player_scene.instantiate()
	if start:
		player.position = start.position
	else:
		push_warning("No PlayerStart found — spawning player at scene origin")
	add_child(player)



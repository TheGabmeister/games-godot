extends Node

var player: Player

var _player_scene: PackedScene = preload("res://scenes/player.tscn")
var _hud_scene: PackedScene = preload("res://scenes/hud.tscn")

const HUD := preload("res://scripts/hud/hud.gd")


func _ready() -> void:
	_find_player_start.call_deferred()


func _find_player_start() -> void:
	var markers := get_tree().get_nodes_in_group(&"player_start")
	if markers.is_empty():
		return
	var marker: Marker2D = markers[0] as Marker2D
	var stage := marker.get_parent()
	player = _player_scene.instantiate()
	player.position = marker.position
	stage.add_child(player)
	var hud: HUD = _hud_scene.instantiate()
	hud.connect_to_player(player)
	stage.add_child(hud)

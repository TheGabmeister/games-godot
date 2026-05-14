extends Node2D

@onready var player: Player = $Player
@onready var hud := $HUD


func _ready() -> void:
	hud.connect_to_player(player)

extends Node2D

@onready var player: Player = $Player
@onready var hud := $HUD


func _ready() -> void:
	@warning_ignore("unsafe_method_access")
	hud.connect_to_player(player)

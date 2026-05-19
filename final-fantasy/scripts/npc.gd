extends StaticBody2D

@export var sprite_texture: Texture2D
@export var dialogue: Array[String] = ["..."]
@export var npc_name: String = "NPC"

@onready var sprite: Sprite2D = $Sprite2D
@onready var interaction_area: Area2D = $InteractionArea

func _ready() -> void:
	if sprite_texture:
		sprite.texture = sprite_texture

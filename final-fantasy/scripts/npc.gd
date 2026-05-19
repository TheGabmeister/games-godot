extends StaticBody2D

@export var sprite_texture: Texture2D
@export_file("*.json") var dialogue_file: String
@export var dialogue_id: String

@onready var sprite: Sprite2D = $Sprite2D

var npc_name: String
var dialogue: Array[String]

func _ready() -> void:
	if sprite_texture:
		sprite.texture = sprite_texture
	if dialogue_file and dialogue_id:
		var data: Dictionary = DialogueData.get_dialogue(dialogue_file, dialogue_id)
		npc_name = data.get("name", "???")
		var lines: Array = data.get("lines", ["..."])
		dialogue.assign(lines)

func interact() -> void:
	GameState.transition(GameState.State.DIALOGUE)
	var node := get_tree().get_first_node_in_group(Groups.DIALOGUE_BOX)
	if node is DialogueBox:
		node.start(npc_name, dialogue)

extends StaticBody2D

@export var dialogue: DialogueData

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	add_to_group("interactable")
	animated_sprite.play("idle_down")

func interact() -> void:
	if dialogue == null:
		return
	var dialogue_box := get_tree().get_first_node_in_group(Groups.DIALOGUE_BOX)
	dialogue_box.start(dialogue)

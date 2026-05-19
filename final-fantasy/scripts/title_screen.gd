extends Control

@onready var new_game_label: Label = %NewGameLabel
@onready var cursor: Label = %Cursor

func _ready() -> void:
	new_game_label.grab_focus()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("confirm"):
		get_tree().change_scene_to_file("res://_scenes/test_movement.tscn")

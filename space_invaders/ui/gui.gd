extends Node

@export var score_one: Label
@export var score_two: Label

func _enter_tree() -> void:
	GameEvents.update_score.connect(_update_score)

func _exit_tree() -> void:
	GameEvents.update_score.disconnect(_update_score)
	
func _update_score(value: int) -> void:
	score_one.text = str(value)
	pass

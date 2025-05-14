extends Node

@export var _score_one: Label
#@export var _score_two: Label
@export var _hi_score: Label

func _enter_tree() -> void:
	GameEvents.update_score.connect(_update_score)
	GameEvents.update_hi_score.connect(_update_hi_score)

func _exit_tree() -> void:
	GameEvents.update_score.disconnect(_update_score)
	GameEvents.update_hi_score.disconnect(_update_hi_score)
	
func _update_score(value: int) -> void:
	_score_one.text = str(value)

func _update_hi_score(value: int) -> void:
	_hi_score.text = str(value)

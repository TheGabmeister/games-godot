extends CanvasLayer

var _can_restart: bool = false

@onready var _score_label: Label = $ScoreLabel
@onready var _start_label: Label = $StartLabel
@onready var _game_over_label: Label = $GameOverLabel
@onready var _final_score_label: Label = $FinalScoreLabel
@onready var _restart_label: Label = $RestartLabel


func _ready() -> void:
	GameManager.game_started.connect(_on_game_started)
	GameManager.game_over.connect(_on_game_over)
	GameManager.score_changed.connect(_on_score_changed)

	_score_label.visible = false
	_start_label.visible = true
	_game_over_label.visible = false
	_final_score_label.visible = false
	_restart_label.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if _can_restart and event.is_action_pressed("flap"):
		_can_restart = false
		GameManager.start_game()


func _on_game_started() -> void:
	_score_label.visible = true
	_start_label.visible = false
	_game_over_label.visible = false
	_final_score_label.visible = false
	_restart_label.visible = false
	_can_restart = false


func _on_game_over() -> void:
	_game_over_label.visible = true
	_final_score_label.text = "Score: %d" % GameManager.score
	_final_score_label.visible = true

	await get_tree().create_timer(1.0).timeout
	_restart_label.visible = true
	_can_restart = true


func _on_score_changed(new_score: int) -> void:
	_score_label.text = str(new_score)

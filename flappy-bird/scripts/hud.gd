extends CanvasLayer

@onready var _score_label: Label = $ScoreLabel
@onready var _start_label: Label = $StartLabel
@onready var _game_over_label: Label = $GameOverLabel
@onready var _final_score_label: Label = $FinalScoreLabel
@onready var _restart_label: Label = $RestartLabel


func _ready() -> void:
	GameManager.game_started.connect(_on_game_started)
	GameManager.game_over.connect(_on_game_over)
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.restart_enabled.connect(_on_restart_enabled)

	_score_label.visible = false
	_start_label.visible = GameManager.is_idle
	_game_over_label.visible = false
	_final_score_label.visible = false
	_restart_label.visible = false


func _on_game_started() -> void:
	_score_label.visible = true
	_score_label.text = str(GameManager.score)
	_start_label.visible = false
	_game_over_label.visible = false
	_final_score_label.visible = false
	_restart_label.visible = false


func _on_game_over() -> void:
	_game_over_label.visible = true
	_final_score_label.text = "Score: %d" % GameManager.score
	_final_score_label.visible = true


func _on_score_changed(new_score: int) -> void:
	_score_label.text = str(new_score)


func _on_restart_enabled() -> void:
	_restart_label.visible = true

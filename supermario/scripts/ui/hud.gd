extends CanvasLayer

@onready var score_label: Label = %ScoreLabel
@onready var coin_label: Label = %CoinLabel
@onready var world_label: Label = %WorldLabel
@onready var time_label: Label = %TimeLabel

var _time_warning_active: bool = false


func _ready() -> void:
	layer = 10
	EventBus.score_changed.connect(_on_score_changed)
	EventBus.coins_changed.connect(_on_coins_changed)
	EventBus.time_tick.connect(_on_time_tick)
	EventBus.level_started.connect(_on_level_started)
	_on_score_changed(GameManager.score)
	_on_coins_changed(GameManager.coins)
	_on_level_started(GameManager.current_world, GameManager.current_level)
	_on_time_tick(ceili(GameManager.time_remaining))


func _on_score_changed(new_score: int) -> void:
	score_label.text = "%06d" % new_score


func _on_coins_changed(new_coins: int) -> void:
	coin_label.text = "x%02d" % new_coins


func _on_time_tick(time_remaining: int) -> void:
	time_label.text = str(time_remaining)
	if time_remaining <= 100 and not _time_warning_active:
		_time_warning_active = true
		time_label.add_theme_color_override("font_color", Color.RED)
	elif time_remaining > 100 and _time_warning_active:
		_time_warning_active = false
		time_label.remove_theme_color_override("font_color")


func _on_level_started(world: int, level: int) -> void:
	world_label.text = "%d-%d" % [world, level]
	_time_warning_active = false
	time_label.remove_theme_color_override("font_color")

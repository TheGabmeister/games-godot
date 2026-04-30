extends Node

enum PowerState { SMALL, BIG, FIRE }
enum GameState { TITLE, PLAYING, PAUSED, GAME_OVER, LEVEL_COMPLETE, TRANSITIONING }

const LevelConfig := preload("res://scripts/config/level_config.gd")

var levels: Array[Resource] = [
	preload("res://resources/config/level_1_1.tres"),
	preload("res://resources/config/level_1_2.tres"),
]

var score: int = 0
var coins: int = 0
var lives: int = 3
var time_remaining: float = 400.0
var current_power_state: PowerState = PowerState.SMALL
var game_state: GameState = GameState.TITLE

var _level_index: int = 0
var _timer_active: bool = false
var _last_time_tick: int = -1


func _ready() -> void:
	EventBus.player_died.connect(_on_player_died)
	EventBus.level_completed.connect(_on_level_completed)


func _process(delta: float) -> void:
	if _timer_active and game_state == GameState.PLAYING:
		time_remaining -= delta
		if time_remaining <= 0.0:
			time_remaining = 0.0
			_timer_active = false
			EventBus.player_died.emit()
		else:
			var current_tick: int = ceili(time_remaining)
			if current_tick != _last_time_tick:
				_last_time_tick = current_tick
				EventBus.time_tick.emit(current_tick)


func start_new_game() -> void:
	_reset_run_state()
	_enter_level(0)


func advance_to_next_level() -> void:
	if _level_index + 1 >= levels.size():
		return_to_title()
		return
	_enter_level(_level_index + 1)


func respawn_current_level() -> void:
	current_power_state = PowerState.SMALL
	_enter_level(_level_index)


func return_to_title() -> void:
	set_game_state(GameState.TITLE)
	get_tree().change_scene_to_file("res://scenes/ui/title_screen.tscn")


func reset_for_title() -> void:
	_reset_run_state()
	_timer_active = false
	game_state = GameState.TITLE


func _enter_level(index: int) -> void:
	_level_index = index
	var config := levels[index] as LevelConfig
	set_game_state(GameState.TRANSITIONING)
	get_tree().change_scene_to_packed(config.scene)
	set_game_state(GameState.PLAYING)
	_start_level(config)


func _start_level(config: LevelConfig) -> void:
	time_remaining = config.time_limit
	_last_time_tick = -1
	_timer_active = true
	if config.music:
		EventBus.music_requested.emit(config.music)
	EventBus.level_started.emit(config.display_name)


func _reset_run_state() -> void:
	score = 0
	coins = 0
	lives = 3
	_level_index = 0
	current_power_state = PowerState.SMALL


func add_score(points: int, position: Vector2 = Vector2.ZERO) -> void:
	score += points
	EventBus.score_awarded.emit(points, position)
	EventBus.score_changed.emit(score)


func add_coin(position: Vector2 = Vector2.ZERO) -> void:
	coins += 1
	EventBus.coin_collected.emit(position)
	EventBus.coins_changed.emit(coins)
	add_score(200, position)
	if coins >= 100:
		coins -= 100
		earn_one_up()


func lose_life() -> void:
	lives -= 1
	EventBus.lives_changed.emit(lives)
	if lives <= 0:
		set_game_state(GameState.GAME_OVER)
		EventBus.music_stop_requested.emit()
		EventBus.game_over.emit()
	else:
		EventBus.player_respawned.emit()
		respawn_current_level.call_deferred()


func set_power_state(state: PowerState) -> void:
	var old := current_power_state
	current_power_state = state
	EventBus.player_power_state_changed.emit(old, state)
	if state > old:
		EventBus.player_powered_up.emit(_power_state_name(state))
	elif state < old:
		EventBus.player_damaged.emit()


func set_game_state(state: GameState) -> void:
	game_state = state
	match state:
		GameState.PAUSED:
			EventBus.game_paused.emit()
		GameState.PLAYING:
			EventBus.game_resumed.emit()
		GameState.GAME_OVER:
			_timer_active = false


func stop_level_timer() -> void:
	_timer_active = false


func get_current_level() -> Resource:
	if _level_index >= 0 and _level_index < levels.size():
		return levels[_level_index]
	return null


func earn_one_up() -> void:
	lives += 1
	EventBus.one_up_earned.emit()
	EventBus.lives_changed.emit(lives)


func _on_player_died() -> void:
	_timer_active = false
	EventBus.music_stop_requested.emit()


func _on_level_completed() -> void:
	_timer_active = false
	EventBus.music_stop_requested.emit()
	var time_bonus := ceili(time_remaining) * 50
	add_score(time_bonus)
	set_game_state(GameState.LEVEL_COMPLETE)


func _power_state_name(state: PowerState) -> StringName:
	match state:
		PowerState.SMALL:
			return &"small"
		PowerState.BIG:
			return &"big"
		PowerState.FIRE:
			return &"fire"
	return &"small"

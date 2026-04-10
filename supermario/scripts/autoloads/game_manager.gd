extends Node

enum PowerState { SMALL, BIG, FIRE }
enum GameState { TITLE, PLAYING, PAUSED, GAME_OVER, LEVEL_COMPLETE, TRANSITIONING }

const LEVEL_SCENES: Dictionary = {
	"1-1": "res://scenes/levels/world_1_1.tscn",
	"1-2": "res://scenes/levels/world_1_2.tscn",
}

const LEVEL_ORDER: Array[String] = ["1-1", "1-2"]

var score: int = 0
var coins: int = 0
var lives: int = 3
var time_remaining: float = 400.0
var current_world: int = 1
var current_level: int = 1
var current_power_state: PowerState = PowerState.SMALL
var game_state: GameState = GameState.TITLE

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
	await _enter_level(LEVEL_SCENES[LEVEL_ORDER[0]])


func advance_to_next_level() -> void:
	var key := get_current_level_key()
	var idx := LEVEL_ORDER.find(key)
	if idx < 0 or idx + 1 >= LEVEL_ORDER.size():
		# No more levels — back to title.
		return_to_title()
		return
	var next_key: String = LEVEL_ORDER[idx + 1]
	var parts := next_key.split("-")
	current_world = int(parts[0])
	current_level = int(parts[1])
	# power_state preserved across level transitions (classic SMB behavior)
	await _enter_level(LEVEL_SCENES[next_key])


func respawn_current_level() -> void:
	# Player lost a life — drop back to Small Mario and reload the level.
	current_power_state = PowerState.SMALL
	var key := get_current_level_key()
	await _enter_level(LEVEL_SCENES[key])


func return_to_title() -> void:
	set_game_state(GameState.TITLE)
	SceneManager.change_scene("res://scenes/ui/title_screen.tscn")


func reset_for_title() -> void:
	_reset_run_state()
	_timer_active = false
	game_state = GameState.TITLE


# --- Level transition flow ---
# Single source of truth for "load a level scene and start playing".
# Callers: start_new_game, advance_to_next_level, respawn_current_level.
func _enter_level(scene_path: String) -> void:
	set_game_state(GameState.TRANSITIONING)
	await SceneManager.fade_out()
	SceneManager.change_scene_no_fade(scene_path)
	await SceneManager.show_level_intro(current_world, current_level, lives)
	set_game_state(GameState.PLAYING)
	start_level_timer()


func _reset_run_state() -> void:
	score = 0
	coins = 0
	lives = 3
	current_world = 1
	current_level = 1
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
		EventBus.game_over.emit()
	else:
		EventBus.player_respawned.emit()
		# Defer the actual reload so death-state callers finish cleanly
		# before the scene is swapped out from under them.
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


func start_level_timer() -> void:
	time_remaining = 400.0
	_last_time_tick = -1
	_timer_active = true
	EventBus.level_started.emit(current_world, current_level)


func stop_level_timer() -> void:
	_timer_active = false


func _on_player_died() -> void:
	_timer_active = false


func _on_level_completed() -> void:
	_timer_active = false
	var time_bonus := ceili(time_remaining) * 50
	add_score(time_bonus)
	set_game_state(GameState.LEVEL_COMPLETE)


func earn_one_up() -> void:
	lives += 1
	EventBus.one_up_earned.emit()
	EventBus.lives_changed.emit(lives)


func get_current_level_key() -> String:
	return "%d-%d" % [current_world, current_level]


func _power_state_name(state: PowerState) -> StringName:
	match state:
		PowerState.SMALL:
			return &"small"
		PowerState.BIG:
			return &"big"
		PowerState.FIRE:
			return &"fire"
	return &"small"

extends Node

enum GameState {
	IDLE,
	PLAYING,
	GAME_OVER,
}

signal game_started
signal game_over
signal score_changed(new_score: int)
signal restart_enabled
signal state_changed(new_state: GameState)

var score: int = 0
var state: GameState = GameState.IDLE
var _can_restart: bool = false

const RESTART_DELAY_SECONDS: float = 1.0

var is_idle: bool:
	get:
		return state == GameState.IDLE

var is_playing: bool:
	get:
		return state == GameState.PLAYING

var is_game_over: bool:
	get:
		return state == GameState.GAME_OVER

var can_restart: bool:
	get:
		return _can_restart


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("flap"):
		return

	if is_idle or (is_game_over and can_restart):
		start_game()


func start_game() -> void:
	if is_playing:
		return

	score = 0
	_can_restart = false
	_set_state(GameState.PLAYING)
	score_changed.emit(score)
	game_started.emit()


func end_game() -> void:
	if is_game_over:
		return

	_can_restart = false
	_set_state(GameState.GAME_OVER)
	game_over.emit()
	_enable_restart_after_delay()


func add_score() -> void:
	if not is_playing:
		return
	score += 1
	score_changed.emit(score)


func _enable_restart_after_delay() -> void:
	await get_tree().create_timer(RESTART_DELAY_SECONDS).timeout
	if not is_game_over:
		return

	_can_restart = true
	restart_enabled.emit()


func _set_state(new_state: GameState) -> void:
	if state == new_state:
		return

	state = new_state
	state_changed.emit(state)

extends Node

enum PowerState { SMALL, BIG, FIRE }
enum GameState { TITLE, PLAYING, PAUSED, GAME_OVER, LEVEL_COMPLETE, TRANSITIONING }


# .gd autoloads can't use @export, so game-wide config lives in a .tres editable in the inspector.
const _config := preload("res://resources/config/game_config.tres")

var score: int = 0
var coins: int = 0
var lives: int = 3
var current_power_state: PowerState = PowerState.SMALL
var game_state: GameState = GameState.TITLE

var _level_index: int = 0


func _ready() -> void:
	EventBus.level_completed.connect(_on_level_completed)


func start_new_game() -> void:
	_reset_run_state()
	_enter_level(0)


func advance_to_next_level() -> void:
	if _level_index + 1 >= _config.levels.size():
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
	game_state = GameState.TITLE


func _enter_level(index: int) -> void:
	_level_index = index
	var config := _config.levels[index]
	set_game_state(GameState.TRANSITIONING)
	_change_to_level_scene(config)
	set_game_state(GameState.PLAYING)
	_start_level(config)


func _start_level(config: Resource) -> void:
	if config.music:
		EventBus.music_requested.emit(config.music)
	EventBus.level_started.emit(config.display_name)


func _change_to_level_scene(config: Resource) -> void:
	var next_scene: Node = config.scene.instantiate()
	next_scene.set("level_config", config)

	var tree := get_tree()
	var old_scene := tree.current_scene
	if old_scene:
		old_scene.queue_free()

	tree.root.add_child(next_scene)
	tree.current_scene = next_scene


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


func get_current_level() -> Resource:
	if _level_index >= 0 and _level_index < _config.levels.size():
		return _config.levels[_level_index]
	return null


func earn_one_up() -> void:
	lives += 1
	EventBus.one_up_earned.emit()
	EventBus.lives_changed.emit(lives)


func _on_level_completed() -> void:
	EventBus.music_stop_requested.emit()
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

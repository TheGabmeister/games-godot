extends Node2D

const LevelConfig := preload("res://scripts/config/level_config.gd")

@export var level_config: LevelConfig
@export var player_scene: PackedScene

var player: CharacterBody2D
var time_remaining: float = 0.0

var _last_time_tick: int = -1
var _timer_active: bool = false


func _ready() -> void:
	EventBus.flagpole_reached.connect(_on_flagpole_reached)
	EventBus.level_completed.connect(_on_level_completed)
	_start_timer()
	_spawn_player()
	player.died.connect(_on_player_died)
	player.death_animation_finished.connect(_on_death_animation_finished)


func _process(delta: float) -> void:
	if _timer_active and GameManager.game_state == GameManager.GameState.PLAYING:
		time_remaining -= delta
		if time_remaining <= 0.0:
			time_remaining = 0.0
			_stop_timer()
			player.die()
		else:
			var current_tick: int = ceili(time_remaining)
			if current_tick != _last_time_tick:
				_last_time_tick = current_tick
				EventBus.time_tick.emit(current_tick)


func _on_player_died() -> void:
	_stop_timer()
	EventBus.music_stop_requested.emit()


func _on_death_animation_finished() -> void:
	GameManager.lose_life()


func _on_flagpole_reached(_height_ratio: float) -> void:
	_stop_timer()


func _on_level_completed() -> void:
	_stop_timer()
	var time_bonus := ceili(time_remaining) * 50
	GameManager.add_score(time_bonus)


func _start_timer() -> void:
	if level_config == null:
		push_warning("No level_config assigned; level timer will stay inactive")
		EventBus.time_tick.emit(0)
		return
	time_remaining = level_config.time_limit
	_timer_active = true
	_emit_time_tick()


func _stop_timer() -> void:
	_timer_active = false


func _emit_time_tick() -> void:
	var current_tick: int = ceili(time_remaining)
	_last_time_tick = current_tick
	EventBus.time_tick.emit(current_tick)


func _spawn_player() -> void:
	var start := get_node_or_null("PlayerStart") as Marker2D
	player = player_scene.instantiate()
	if start:
		player.position = start.position
	else:
		push_warning("No PlayerStart found — spawning player at scene origin")
	add_child(player)



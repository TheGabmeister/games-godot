extends Node2D

@export var player_scene: PackedScene

var player: CharacterBody2D

var _last_time_tick: int = -1


func _ready() -> void:
	_spawn_player()
	player.died.connect(_on_player_died)
	player.death_animation_finished.connect(_on_death_animation_finished)


func _process(delta: float) -> void:
	if GameManager.timer_active and GameManager.game_state == GameManager.GameState.PLAYING:
		GameManager.time_remaining -= delta
		if GameManager.time_remaining <= 0.0:
			GameManager.time_remaining = 0.0
			GameManager.timer_active = false
			player.die()
		else:
			var current_tick: int = ceili(GameManager.time_remaining)
			if current_tick != _last_time_tick:
				_last_time_tick = current_tick
				EventBus.time_tick.emit(current_tick)


func _on_player_died() -> void:
	GameManager.timer_active = false
	EventBus.music_stop_requested.emit()


func _on_death_animation_finished() -> void:
	GameManager.lose_life()


func _spawn_player() -> void:
	var start := get_node_or_null("PlayerStart") as Marker2D
	player = player_scene.instantiate()
	if start:
		player.position = start.position
	else:
		push_warning("No PlayerStart found — spawning player at scene origin")
	add_child(player)



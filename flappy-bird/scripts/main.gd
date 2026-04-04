extends Node2D

const PIPE_PAIR_SCENE: PackedScene = preload("res://scenes/pipe_pair.tscn")
const PIPE_SPAWN_X: float = 520.0
const GAP_Y_MIN: float = 150.0
const GAP_Y_MAX: float = 570.0
const GROUND_HEIGHT: float = 50.0
const SCREEN_WIDTH: float = 480.0
const SCREEN_HEIGHT: float = 720.0

@onready var _pipe_container: Node2D = $PipeContainer
@onready var _spawn_timer: Timer = $PipeSpawnTimer


func _ready() -> void:
	GameManager.game_started.connect(_on_game_started)
	GameManager.game_over.connect(_on_game_over)
	_spawn_timer.wait_time = 1.6
	_spawn_timer.one_shot = false
	_spawn_timer.timeout.connect(_on_spawn_timer_timeout)


func _on_game_started() -> void:
	for pipe in _pipe_container.get_children():
		pipe.queue_free()
	_spawn_timer.start()


func _on_game_over() -> void:
	_spawn_timer.stop()


func _on_spawn_timer_timeout() -> void:
	var pipe_pair := PIPE_PAIR_SCENE.instantiate()
	pipe_pair.position.x = PIPE_SPAWN_X
	pipe_pair.gap_center_y = randf_range(GAP_Y_MIN, GAP_Y_MAX)
	_pipe_container.add_child(pipe_pair)


func _draw() -> void:
	# Ground base
	var ground_y: float = SCREEN_HEIGHT - GROUND_HEIGHT
	draw_rect(Rect2(0, ground_y, SCREEN_WIDTH, GROUND_HEIGHT), Color(0.545, 0.271, 0.075))

	# Grass stripe on top of ground
	draw_rect(Rect2(0, ground_y, SCREEN_WIDTH, 8), Color(0.133, 0.545, 0.133))

	# Ground texture lines
	for i in range(0, int(SCREEN_WIDTH), 20):
		draw_line(
			Vector2(i, ground_y + 20),
			Vector2(i + 10, ground_y + 20),
			Color(0.396, 0.263, 0.129),
			2.0
		)

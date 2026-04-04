extends Node2D

const PIPE_PAIR_SCENE: PackedScene = preload("res://scenes/pipe_pair.tscn")

@onready var _ground: StaticBody2D = $Ground
@onready var _ground_collision: CollisionShape2D = $Ground/CollisionShape2D
@onready var _pipe_container: Node2D = $PipeContainer
@onready var _spawn_timer: Timer = $PipeSpawnTimer


func _ready() -> void:
	GameManager.game_started.connect(_on_game_started)
	GameManager.game_over.connect(_on_game_over)
	_setup_ground()
	_spawn_timer.wait_time = Config.PIPE_SPAWN_INTERVAL
	_spawn_timer.one_shot = false
	_spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	queue_redraw()


func _on_game_started() -> void:
	for pipe in _pipe_container.get_children():
		pipe.queue_free()
	_spawn_timer.start()


func _on_game_over() -> void:
	_spawn_timer.stop()


func _on_spawn_timer_timeout() -> void:
	var pipe_pair := PIPE_PAIR_SCENE.instantiate()
	pipe_pair.position.x = Config.PIPE_SPAWN_X
	pipe_pair.gap_center_y = randf_range(Config.GAP_Y_MIN, Config.GAP_Y_MAX)
	_pipe_container.add_child(pipe_pair)


func _setup_ground() -> void:
	var ground_shape := RectangleShape2D.new()
	ground_shape.size = Vector2(Config.SCREEN_WIDTH, Config.GROUND_HEIGHT)
	_ground_collision.shape = ground_shape
	_ground.position = Vector2(
		Config.SCREEN_WIDTH / 2.0,
		Config.GROUND_TOP_Y + Config.GROUND_HEIGHT / 2.0
	)


func _draw() -> void:
	# Ground base
	var ground_y: float = Config.GROUND_TOP_Y
	draw_rect(Rect2(0, ground_y, Config.SCREEN_WIDTH, Config.GROUND_HEIGHT), Color(0.545, 0.271, 0.075))

	# Grass stripe on top of ground
	draw_rect(Rect2(0, ground_y, Config.SCREEN_WIDTH, Config.GROUND_GRASS_HEIGHT), Color(0.133, 0.545, 0.133))

	# Ground texture lines
	for i in range(0, int(Config.SCREEN_WIDTH), 20):
		draw_line(
			Vector2(i, ground_y + 20),
			Vector2(i + 10, ground_y + 20),
			Color(0.396, 0.263, 0.129),
			2.0
		)

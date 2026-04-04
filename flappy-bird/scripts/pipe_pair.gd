extends Node2D


var gap_center_y: float = 360.0
var _scored: bool = false

@onready var _top_collision: CollisionShape2D = $TopPipe/CollisionShape2D
@onready var _bottom_collision: CollisionShape2D = $BottomPipe/CollisionShape2D
@onready var _score_collision: CollisionShape2D = $ScoreZone/CollisionShape2D


func _ready() -> void:
	_setup_pipes()
	$ScoreZone.body_entered.connect(_on_score_zone_body_entered)


func _physics_process(delta: float) -> void:
	if not GameManager.is_playing:
		return
	position.x -= Config.PIPE_SPEED * delta
	if position.x < -Config.PIPE_WIDTH:
		queue_free()


func _setup_pipes() -> void:
	var gap_top: float = gap_center_y - Config.GAP_SIZE / 2.0
	var gap_bottom: float = gap_center_y + Config.GAP_SIZE / 2.0

	# Top pipe collision
	var top_height: float = gap_top
	var top_shape := RectangleShape2D.new()
	top_shape.size = Vector2(Config.PIPE_WIDTH, top_height)
	$TopPipe.position = Vector2(0, top_height / 2.0)
	_top_collision.shape = top_shape

	# Bottom pipe collision
	var bottom_height: float = Config.GROUND_TOP_Y - gap_bottom
	var bottom_shape := RectangleShape2D.new()
	bottom_shape.size = Vector2(Config.PIPE_WIDTH, bottom_height)
	$BottomPipe.position = Vector2(0, gap_bottom + bottom_height / 2.0)
	_bottom_collision.shape = bottom_shape

	# Score zone (thin vertical area in the gap)
	var score_shape := RectangleShape2D.new()
	score_shape.size = Vector2(10.0, Config.GAP_SIZE)
	$ScoreZone.position = Vector2(0, gap_center_y)
	_score_collision.shape = score_shape

	queue_redraw()


func _draw() -> void:
	var gap_top: float = gap_center_y - Config.GAP_SIZE / 2.0
	var gap_bottom: float = gap_center_y + Config.GAP_SIZE / 2.0
	var cap_extra: float = 10.0
	var cap_height: float = 26.0

	var pipe_color := Color(0.133, 0.545, 0.133)
	var pipe_dark := Color(0.106, 0.420, 0.106)
	var cap_color := Color(0.180, 0.545, 0.180)

	# Top pipe body
	var top_rect := Rect2(-Config.PIPE_WIDTH / 2.0, 0.0, Config.PIPE_WIDTH, gap_top)
	draw_rect(top_rect, pipe_color)
	draw_rect(top_rect, pipe_dark, false, 3.0)

	# Top pipe cap
	var top_cap := Rect2(
		-(Config.PIPE_WIDTH + cap_extra) / 2.0,
		gap_top - cap_height,
		Config.PIPE_WIDTH + cap_extra,
		cap_height
	)
	draw_rect(top_cap, cap_color)
	draw_rect(top_cap, pipe_dark, false, 3.0)

	# Bottom pipe body
	var bottom_rect := Rect2(
		-Config.PIPE_WIDTH / 2.0,
		gap_bottom,
		Config.PIPE_WIDTH,
		Config.GROUND_TOP_Y - gap_bottom
	)
	draw_rect(bottom_rect, pipe_color)
	draw_rect(bottom_rect, pipe_dark, false, 3.0)

	# Bottom pipe cap
	var bottom_cap := Rect2(
		-(Config.PIPE_WIDTH + cap_extra) / 2.0,
		gap_bottom,
		Config.PIPE_WIDTH + cap_extra,
		cap_height
	)
	draw_rect(bottom_cap, cap_color)
	draw_rect(bottom_cap, pipe_dark, false, 3.0)


func _on_score_zone_body_entered(_body: Node2D) -> void:
	if _scored:
		return
	_scored = true
	GameManager.add_score()

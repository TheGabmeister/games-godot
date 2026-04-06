class_name Pickup extends Area2D

@export var item: ItemData

const COLLECT_RANGE := 8.0
const MAGNETIZE_SPEED := 80.0
const DESPAWN_TIME := 10.0
const BOB_SPEED := 4.0
const BOB_AMPLITUDE := 2.0
const SPAWN_SCATTER := 12.0

var _bob_time: float = 0.0
var _despawn_timer: float = DESPAWN_TIME
var _player: CharacterBody2D = null


func _ready() -> void:
	# Random bob phase so multiple pickups don't sync
	_bob_time = randf() * TAU

	# Scatter slightly from spawn point
	position += Vector2(randf_range(-SPAWN_SCATTER, SPAWN_SCATTER), randf_range(-SPAWN_SCATTER, SPAWN_SCATTER))

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _physics_process(delta: float) -> void:
	_despawn_timer -= delta
	if _despawn_timer <= 0.0:
		queue_free()
		return

	# Fade out near despawn
	if _despawn_timer < 2.0:
		modulate.a = _despawn_timer / 2.0

	_bob_time += delta

	# Magnetize toward player if nearby
	if _player:
		var dist: float = global_position.distance_to(_player.global_position)
		if dist < COLLECT_RANGE:
			_collect()
			return
		var dir: Vector2 = (_player.global_position - global_position).normalized()
		position += dir * MAGNETIZE_SPEED * delta

	queue_redraw()


func _draw() -> void:
	if not item:
		draw_circle(Vector2.ZERO, 3.0, Color.WHITE)
		return

	var bob_y: float = sin(_bob_time * BOB_SPEED) * BOB_AMPLITUDE
	var color: Color = item.icon_color

	match item.resource_key:
		&"rupees":
			# Diamond shape
			draw_colored_polygon(PackedVector2Array([
				Vector2(0, -4 + bob_y),
				Vector2(3, 0 + bob_y),
				Vector2(0, 4 + bob_y),
				Vector2(-3, 0 + bob_y),
			]), color)
		&"hearts":
			# Circle heart
			draw_circle(Vector2(0, bob_y), 3.5, color)
			draw_circle(Vector2(-1.5, -1.5 + bob_y), 2.0, color.lightened(0.3))
			draw_circle(Vector2(1.5, -1.5 + bob_y), 2.0, color.lightened(0.3))
		_:
			# Generic circle
			draw_circle(Vector2(0, bob_y), 3.0, color)
			draw_circle(Vector2(0, bob_y), 1.5, color.lightened(0.3))


func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D:
		_player = body as CharacterBody2D


func _on_body_exited(body: Node) -> void:
	if body == _player:
		_player = null


func _collect() -> void:
	if item:
		PlayerState.acquire(item)
		match item.resource_key:
			&"hearts":
				AudioManager.play_sfx(&"pickup_heart")
			&"rupees":
				AudioManager.play_sfx(&"pickup_rupee")
			_:
				AudioManager.play_sfx(&"pickup")
	queue_free()

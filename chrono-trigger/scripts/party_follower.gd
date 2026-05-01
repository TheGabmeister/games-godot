extends CharacterBody2D

const SPEED := 150.0
const STOP_DISTANCE := 24.0

@export var leader_path: NodePath
@export var follow_delay: int = 20
@export var data: CharacterData

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var facing := Vector2.DOWN
var _leader: Node2D

func _ready() -> void:
	_leader = get_node_or_null(leader_path)
	if animated_sprite.sprite_frames:
		_play_idle_animation()

func _physics_process(_delta: float) -> void:
	if GameState.current != GameState.State.FIELD:
		velocity = Vector2.ZERO
		return
	if _leader == null:
		return
	if not _leader.has_meta("position_history"):
		return

	if global_position.distance_to(_leader.global_position) <= STOP_DISTANCE:
		velocity = Vector2.ZERO
		_play_idle_animation()
		move_and_slide()
		return

	var history: PackedVector2Array = _leader.get_meta("position_history")
	if history.size() < follow_delay:
		return

	var target_pos := history[history.size() - follow_delay]
	var diff := target_pos - global_position
	if diff.length() < 2.0:
		velocity = Vector2.ZERO
		_play_idle_animation()
	else:
		velocity = diff.normalized() * SPEED
		facing = diff.normalized().snapped(Vector2.ONE).normalized()
		_play_walk_animation()

	move_and_slide()

func _play_walk_animation() -> void:
	animated_sprite.play("walk_" + _direction_name())

func _play_idle_animation() -> void:
	animated_sprite.play("idle_" + _direction_name())

func _direction_name() -> String:
	if abs(facing.x) > abs(facing.y):
		return "right" if facing.x > 0 else "left"
	else:
		return "down" if facing.y > 0 else "up"

func get_facing_direction_name() -> String:
	return _direction_name()

func play_attack() -> void:
	var anim := "attack_" + _direction_name()
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(anim):
		animated_sprite.play(anim)

func play_idle() -> void:
	_play_idle_animation()

func play_hit(hit_direction: Vector2) -> void:
	_play_idle_animation()
	var start_pos := global_position
	var recoil := hit_direction
	if recoil == Vector2.ZERO:
		recoil = Vector2.LEFT
	var tween := create_tween()
	tween.tween_property(self, "global_position", start_pos + recoil * 8.0, 0.06)
	tween.tween_property(self, "global_position", start_pos - recoil * 4.0, 0.06)
	tween.tween_property(self, "global_position", start_pos, 0.08)

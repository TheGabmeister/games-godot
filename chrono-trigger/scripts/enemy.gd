extends Area2D

@export var data: Resource
@export var encounter_group: String = ""
@export var is_boss: bool = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var battle_started := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("idle"):
		animated_sprite.play("idle")

func _on_body_entered(body: Node2D) -> void:
	if battle_started:
		return
	if GameState.current != GameState.State.FIELD:
		return
	if not body is CharacterBody2D:
		return

	var battle_manager := get_tree().get_first_node_in_group(Groups.BATTLE_MANAGER)
	if battle_manager == null:
		return

	battle_started = true
	set_deferred("monitoring", false)
	battle_manager.start_battle(self)

func set_battle_collision_enabled(enabled: bool) -> void:
	collision_shape.set_deferred("disabled", not enabled)

func reset_for_encounter() -> void:
	battle_started = false
	set_deferred("monitoring", true)
	set_battle_collision_enabled(true)
	modulate.a = 1.0

func play_idle() -> void:
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("idle"):
		animated_sprite.play("idle")

func play_attack() -> void:
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("attack"):
		animated_sprite.play("attack")

func play_hit(_hit_direction: Vector2 = Vector2.ZERO) -> void:
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("hit"):
		animated_sprite.play("hit")

func play_die() -> void:
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("die"):
		animated_sprite.play("die")

func play_death() -> void:
	play_die()
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	await tween.finished

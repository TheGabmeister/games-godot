extends Node2D

const ScorePopupScene := preload("res://scenes/effects/score_popup.tscn")
const BrickParticleScene := preload("res://scenes/effects/brick_particle.tscn")
const StompPuffScene := preload("res://scenes/effects/stomp_puff.tscn")
const CoinPopScene := preload("res://scenes/effects/coin_pop.tscn")

@export var effects_config: Resource  # EffectsConfig


func _ready() -> void:
	EventBus.score_awarded.connect(_on_score_awarded)
	EventBus.block_broken.connect(_on_block_broken)
	EventBus.enemy_stomped.connect(_on_enemy_stomped)
	EventBus.item_spawned.connect(_on_item_spawned)


func _on_score_awarded(points: int, pos: Vector2) -> void:
	if pos == Vector2.ZERO:
		return
	var popup := _spawn_effect(ScorePopupScene, pos + Vector2(0, -16), 5)
	popup.setup(points, effects_config)


func _on_block_broken(pos: Vector2) -> void:
	for i in 4:
		var particle := _spawn_effect(BrickParticleScene, pos + Vector2(0, -16), 4)
		var angle: float = -PI * 0.25 - PI * 0.5 * (float(i) / 3.0)
		var speed: float = 240.0 + randf() * 120.0
		particle.setup(Vector2(cos(angle) * speed, sin(angle) * speed))


func _on_enemy_stomped(pos: Vector2) -> void:
	_spawn_effect(StompPuffScene, pos, 4)


func _on_item_spawned(item_type: StringName, pos: Vector2) -> void:
	if item_type == &"coin":
		_spawn_effect(CoinPopScene, pos, 5)


func _spawn_effect(scene: PackedScene, pos: Vector2, z: int) -> Node2D:
	var node := scene.instantiate() as Node2D
	node.global_position = pos
	node.z_index = z
	add_child(node)
	return node

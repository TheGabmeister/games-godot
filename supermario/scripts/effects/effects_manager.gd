extends Node2D

const ScorePopupScript := preload("res://scripts/effects/score_popup.gd")
const BrickParticle := preload("res://scripts/effects/brick_particle.gd")
const StompPuff := preload("res://scripts/effects/stomp_puff.gd")
const CoinPop := preload("res://scripts/effects/coin_pop.gd")

@export var effects_config: Resource  # EffectsConfig


func _ready() -> void:
	EventBus.score_awarded.connect(_on_score_awarded)
	EventBus.block_broken.connect(_on_block_broken)
	EventBus.enemy_stomped.connect(_on_enemy_stomped)
	EventBus.item_spawned.connect(_on_item_spawned)


func _on_score_awarded(points: int, pos: Vector2) -> void:
	if pos == Vector2.ZERO:
		return
	var popup := Node2D.new()
	popup.set_script(ScorePopupScript)
	popup.global_position = pos + Vector2(0, -8)
	popup.z_index = 5
	add_child(popup)
	popup.setup(points, effects_config)


func _on_block_broken(pos: Vector2) -> void:
	for i in 4:
		var particle := Node2D.new()
		particle.set_script(BrickParticle)
		particle.global_position = pos + Vector2(0, -8)
		particle.z_index = 4
		add_child(particle)
		var angle: float = -PI * 0.25 - PI * 0.5 * (float(i) / 3.0)
		var speed: float = 120.0 + randf() * 60.0
		particle.setup(Vector2(cos(angle) * speed, sin(angle) * speed))


func _on_enemy_stomped(pos: Vector2) -> void:
	var puff := Node2D.new()
	puff.set_script(StompPuff)
	puff.global_position = pos
	puff.z_index = 4
	add_child(puff)


func _on_item_spawned(item_type: StringName, pos: Vector2) -> void:
	if item_type == &"coin":
		var coin := Node2D.new()
		coin.set_script(CoinPop)
		coin.global_position = pos
		coin.z_index = 5
		add_child(coin)

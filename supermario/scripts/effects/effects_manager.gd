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
	var popup := _spawn_effect(ScorePopupScript, pos + Vector2(0, -16), 5)
	popup.setup(points, effects_config)


func _on_block_broken(pos: Vector2) -> void:
	for i in 4:
		var particle := _spawn_effect(BrickParticle, pos + Vector2(0, -16), 4)
		var angle: float = -PI * 0.25 - PI * 0.5 * (float(i) / 3.0)
		var speed: float = 240.0 + randf() * 120.0
		particle.setup(Vector2(cos(angle) * speed, sin(angle) * speed))


func _on_enemy_stomped(pos: Vector2) -> void:
	_spawn_effect(StompPuff, pos, 4)


func _on_item_spawned(item_type: StringName, pos: Vector2) -> void:
	if item_type == &"coin":
		_spawn_effect(CoinPop, pos, 5)


# Effects are scriptless Node2Ds with a script attached at runtime, rather
# than .tscn scenes or `class_name`-typed classes. The project avoids
# `class_name` due to a headless-indexing quirk (see CLAUDE.md), and these
# effects have no children/exports/editor work that would justify a scene
# file. Convert any single effect to a `.tscn` if it ever grows children
# or @export tunables.
func _spawn_effect(script: GDScript, pos: Vector2, z: int) -> Node2D:
	var node := Node2D.new()
	node.set_script(script)
	node.global_position = pos
	node.z_index = z
	add_child(node)
	return node

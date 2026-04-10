extends BaseEnemyState

const FIRE_DELAY: float = 0.3
const PROJECTILE_SCENE: PackedScene = preload("res://scenes/projectiles/projectile_base.tscn")

var _timer: float = 0.0
var _fired: bool = false


func enter(_msg: Dictionary = {}) -> void:
	_timer = 0.0
	_fired = false
	_fire_projectile()


func update(delta: float) -> void:
	_timer += delta
	if _timer >= FIRE_DELAY:
		state_machine.transition_to(&"Disappear")


func _fire_projectile() -> void:
	_fired = true

	var player: CharacterBody2D = actor.get_player()
	if not player:
		return

	var dir: Vector2 = (player.global_position - actor.global_position).normalized()
	actor.update_facing(dir)

	var projectile: Projectile = PROJECTILE_SCENE.instantiate() as Projectile
	projectile.speed = 70.0
	projectile.damage = 4
	projectile.damage_type = DamageType.Type.MAGIC
	projectile.source_team = &"enemy"
	projectile.projectile_color = Color(0.6, 0.2, 0.9)
	projectile.deflectable = true
	projectile.direction = dir
	projectile.global_position = actor.global_position

	actor.get_parent().add_child(projectile)

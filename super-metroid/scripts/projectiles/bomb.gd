class_name Bomb
extends Area2D

const FUSE_TIME: float = 3.0
const BLAST_RADIUS: float = 32.0
const BOMB_DAMAGE: int = 30
const BOMB_IMPULSE: float = -300.0

var _timer: float = 0.0
var _exploded: bool = false

@onready var _sprite: Sprite2D = $Sprite2D


func _physics_process(delta: float) -> void:
	_timer += delta
	if _timer >= FUSE_TIME and not _exploded:
		_explode()


func _explode() -> void:
	_exploded = true
	_sprite.visible = false
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()
	var circle := CircleShape2D.new()
	circle.radius = BLAST_RADIUS
	query.shape = circle
	query.transform = global_transform
	query.collision_mask = 2 | 4
	var results := space_state.intersect_shape(query)
	for result: Dictionary in results:
		var collider: Object = result["collider"]
		if collider is Player:
			(collider as Player).velocity.y = BOMB_IMPULSE
		elif collider.has_method(&"take_damage"):
			collider.call(&"take_damage", BOMB_DAMAGE, global_position)
	queue_free()

extends BaseEnemy

## Predefined teleport offsets (relative to spawn position).
## These get converted to global positions in _ready().
@export var teleport_offsets: PackedVector2Array = PackedVector2Array([
	Vector2(-48, -32),
	Vector2(48, -32),
	Vector2(-48, 32),
	Vector2(48, 32),
	Vector2(0, -48),
	Vector2(0, 48),
])

var teleport_positions: PackedVector2Array
var _spawn_position: Vector2


func _ready() -> void:
	super._ready()
	_spawn_position = global_position

	# Build global teleport positions from offsets
	teleport_positions.clear()
	for offset in teleport_offsets:
		teleport_positions.append(_spawn_position + offset)
	# Also include the spawn position itself as a valid spot
	teleport_positions.append(_spawn_position)


func set_invulnerable(val: bool) -> void:
	if val:
		hurtbox.collision_layer = 0
		hurtbox.collision_mask = 0
	else:
		hurtbox.collision_layer = 4  # Enemies
		hurtbox.collision_mask = 8   # PlayerAttacks


func get_random_teleport_position() -> Vector2:
	if teleport_positions.is_empty():
		return global_position
	return teleport_positions[randi() % teleport_positions.size()]


func get_player() -> CharacterBody2D:
	return SceneManager._player

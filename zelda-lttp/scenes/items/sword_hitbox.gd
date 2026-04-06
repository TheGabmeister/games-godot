extends Area2D

@onready var _shape: CollisionShape2D = $SwordShape
var _damage: int = 2
var _direction: Vector2 = Vector2.DOWN

const HITBOX_OFFSET := 10.0
const HITBOX_SIZE := Vector2(14, 12)


func _ready() -> void:
	if not _shape.shape:
		var rect := RectangleShape2D.new()
		rect.size = HITBOX_SIZE
		_shape.shape = rect
	_shape.disabled = true


func activate(direction: Vector2, damage: int) -> void:
	_direction = direction
	_damage = damage
	# Position hitbox in front of player based on facing
	_shape.position = direction * HITBOX_OFFSET
	# Rotate shape for horizontal vs vertical swings
	if absf(direction.x) > absf(direction.y):
		_shape.rotation = 0.0
	else:
		_shape.rotation = PI / 2.0
	_shape.disabled = false
	set_meta("damage", _damage)
	set_meta("damage_type", DamageType.Type.SWORD)
	set_meta("source_direction", _direction)


func deactivate() -> void:
	_shape.disabled = true

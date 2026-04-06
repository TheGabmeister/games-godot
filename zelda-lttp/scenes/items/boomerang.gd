extends Area2D

const SPEED := 120.0
const MAX_DISTANCE := 80.0
const RETURN_SPEED := 140.0
const STUN_DURATION := 1.5

var direction: Vector2 = Vector2.RIGHT
var origin_player: CharacterBody2D = null

var _traveled: float = 0.0
var _returning: bool = false
var _spin_angle: float = 0.0


func _ready() -> void:
	collision_layer = 8   # PlayerAttacks
	collision_mask = 4    # Enemies
	set_meta("damage", 0)
	set_meta("damage_type", DamageType.Type.CONTACT)
	set_meta("knockback_force", 0.0)
	set_meta("source_team", &"player")
	set_meta("effect", DamageType.HitEffect.STUN)

	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 4.0
	shape.shape = circle
	add_child(shape)


func _physics_process(delta: float) -> void:
	_spin_angle += delta * 15.0

	if _returning:
		if not is_instance_valid(origin_player):
			queue_free()
			return
		var to_player: Vector2 = (origin_player.global_position - global_position)
		if to_player.length() < 8.0:
			queue_free()
			return
		position += to_player.normalized() * RETURN_SPEED * delta
	else:
		position += direction * SPEED * delta
		_traveled += SPEED * delta
		if _traveled >= MAX_DISTANCE:
			_returning = true

	queue_redraw()


func _draw() -> void:
	# Spinning V shape
	var c := Color(0.3, 0.5, 0.9)
	var angle := _spin_angle
	for i in range(4):
		var a: float = angle + i * PI / 2.0
		var p: Vector2 = Vector2.from_angle(a) * 4.0
		draw_line(Vector2.ZERO, p, c, 1.5)


func _on_area_entered(area: Area2D) -> void:
	if area is HurtboxComponent:
		_returning = true
	# Collect pickups on contact
	if area is Pickup:
		area._collect()


func _on_body_entered(_body: Node) -> void:
	_returning = true

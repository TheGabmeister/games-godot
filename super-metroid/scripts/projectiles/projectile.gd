class_name Projectile
extends Area2D

@export var speed: float = 400.0
@export var damage: int = 20
@export var max_lifetime: float = 1.0

var direction: Vector2 = Vector2.RIGHT
var _lifetime: float = 0.0


func _ready() -> void:
	var _err := body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	_lifetime += delta
	if _lifetime >= max_lifetime:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.has_method(&"take_damage"):
		body.call(&"take_damage", damage, global_position)
	queue_free()

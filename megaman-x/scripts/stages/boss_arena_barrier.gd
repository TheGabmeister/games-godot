extends Node2D
class_name BossArenaBarrier

@onready var blocker: StaticBody2D = $Blocker
@onready var collision_shape: CollisionShape2D = $Blocker/CollisionShape2D


func _ready() -> void:
	set_locked(false)


func set_locked(locked: bool) -> void:
	visible = locked
	if collision_shape != null:
		collision_shape.set_deferred("disabled", not locked)


func is_locked() -> bool:
	return collision_shape != null and not collision_shape.disabled

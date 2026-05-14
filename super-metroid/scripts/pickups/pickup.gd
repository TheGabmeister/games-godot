class_name Pickup
extends Area2D

enum PickupType { SMALL_ENERGY, LARGE_ENERGY, MISSILE }

@export var pickup_type: PickupType = PickupType.SMALL_ENERGY
@export var recovery_amount: int = 5


func _ready() -> void:
	collision_layer = 32
	collision_mask = 2
	var _err := body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		var p := body as Player
		match pickup_type:
			PickupType.SMALL_ENERGY:
				p.set_energy(p.energy + recovery_amount)
			PickupType.LARGE_ENERGY:
				p.set_energy(p.energy + recovery_amount)
			PickupType.MISSILE:
				p.set_missiles(p.missiles + recovery_amount)
		queue_free()

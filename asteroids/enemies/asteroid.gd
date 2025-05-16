extends EnemyBase

@export var _asteroid_child: PackedScene
@export var _child_amount := 1

func _on_area_2d_area_entered(_area: Area2D):
	
	if _asteroid_child != null:
		for i in _child_amount:
			print("Hello")
		var instance := _asteroid_child.instantiate()
		instance.position = position
		instance.rotation = randf() * TAU
		get_tree().current_scene.call_deffered("add_child", instance)
		
	super._on_area_2d_area_entered(_area)

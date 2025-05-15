extends Area2D

enum BoundaryPos { NORTH, SOUTH, EAST, WEST }
@export var _boundary_pos := BoundaryPos.NORTH

func _on_area_entered(area: Area2D) -> void:
	var other: Node2D = area.owner
	match _boundary_pos:
		BoundaryPos.NORTH:
			other.position = Vector2(other.position.x, GlobalVars.SCREEN_HEIGHT)
		BoundaryPos.SOUTH:
			other.position = Vector2(other.position.x, 0)
		BoundaryPos.EAST:
			other.position = Vector2(0, other.position.y)
		BoundaryPos.WEST:
			other.position = Vector2(GlobalVars.SCREEN_WIDTH, other.position.y)

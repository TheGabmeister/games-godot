extends Camera2D

@export var limit_rect: Rect2 = Rect2(0, 0, 960, 480)


func _ready() -> void:
	limit_left = int(limit_rect.position.x)
	limit_top = int(limit_rect.position.y)
	limit_right = int(limit_rect.position.x + limit_rect.size.x)
	limit_bottom = int(limit_rect.position.y + limit_rect.size.y)

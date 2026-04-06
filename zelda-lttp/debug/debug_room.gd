extends Room

# Debug room for testing Phase 1+ features
# Provides walls, floor, a pit hazard, entry point, and Phase 3 test chests


func _ready() -> void:
	# Give starting ammo for testing skills
	PlayerState.arrows = 30
	PlayerState.bombs = 10
	PlayerState.current_magic = 128
	PlayerState.upgrades[&"sword"] = 1
	PlayerState.upgrades[&"shield"] = 1

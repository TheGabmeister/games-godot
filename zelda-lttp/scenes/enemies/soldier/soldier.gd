extends BaseEnemy

# Level-design exports (Phase 2.4)
@export var patrol_points: PackedVector2Array
@export var patrol_wait_time: float = 1.0
@export var detection_radius: float = 80.0
@export var lose_interest_radius: float = 120.0
@export var patrol_speed: float = 30.0
@export var chase_speed: float = 60.0

extends Resource

@export var walk_speed: float = 260.0
@export var run_speed: float = 420.0
@export var acceleration: float = 1600.0
@export var deceleration: float = 2400.0
@export var air_acceleration: float = 1200.0
@export var turn_acceleration: float = 3200.0
@export var jump_velocity: float = -860.0
@export var jump_release_mult: float = 0.5
@export var gravity: float = 1800.0
@export var fast_fall_gravity: float = 2800.0
@export var max_fall_speed: float = 1000.0
@export var coyote_time: float = 0.08
@export var jump_buffer_time: float = 0.10
@export var small_collision: Vector2 = Vector2(24.0, 28.0)
@export var big_collision: Vector2 = Vector2(24.0, 56.0)
@export var stomp_bounce_velocity: float = -500.0
@export var invincibility_duration: float = 2.0
@export var high_speed_jump_boost: float = 1.12

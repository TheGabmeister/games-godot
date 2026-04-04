extends Resource
class_name GameConfig

@export_group("Bird")
@export var bird_start_x: float = 120.0
@export var bird_idle_bob_amplitude: float = 10.0
@export var bird_out_of_bounds_margin: float = 50.0
@export var gravity: float = 980.0
@export var flap_velocity: float = -330.0
@export var max_fall_speed: float = 600.0
@export var rotation_speed: float = 4.0

@export_group("Ground")
@export var ground_height: float = 50.0
@export var ground_grass_height: float = 8.0

@export_group("Pipes")
@export var pipe_speed: float = 150.0
@export var pipe_width: float = 70.0
@export var gap_size: float = 160.0
@export var pipe_spawn_margin: float = 40.0
@export var gap_y_min: float = 150.0
@export var gap_bottom_margin: float = 20.0
@export var pipe_spawn_interval: float = 1.6

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

var BIRD_START_X: float:
	get:
		return bird_start_x

var BIRD_IDLE_BOB_AMPLITUDE: float:
	get:
		return bird_idle_bob_amplitude

var BIRD_OUT_OF_BOUNDS_MARGIN: float:
	get:
		return bird_out_of_bounds_margin

var GROUND_HEIGHT: float:
	get:
		return ground_height

var GROUND_GRASS_HEIGHT: float:
	get:
		return ground_grass_height

var GRAVITY: float:
	get:
		return gravity

var FLAP_VELOCITY: float:
	get:
		return flap_velocity

var MAX_FALL_SPEED: float:
	get:
		return max_fall_speed

var ROTATION_SPEED: float:
	get:
		return rotation_speed

var PIPE_SPEED: float:
	get:
		return pipe_speed

var PIPE_WIDTH: float:
	get:
		return pipe_width

var GAP_SIZE: float:
	get:
		return gap_size

var PIPE_SPAWN_MARGIN: float:
	get:
		return pipe_spawn_margin

var GAP_Y_MIN: float:
	get:
		return gap_y_min

var GAP_BOTTOM_MARGIN: float:
	get:
		return gap_bottom_margin

var PIPE_SPAWN_INTERVAL: float:
	get:
		return pipe_spawn_interval

var SCREEN_WIDTH: float:
	get:
		return float(ProjectSettings.get_setting("display/window/size/viewport_width"))

var SCREEN_HEIGHT: float:
	get:
		return float(ProjectSettings.get_setting("display/window/size/viewport_height"))

var GROUND_TOP_Y: float:
	get:
		return SCREEN_HEIGHT - GROUND_HEIGHT

var BIRD_START_POSITION: Vector2:
	get:
		return Vector2(BIRD_START_X, SCREEN_HEIGHT / 2.0)

var BIRD_MIN_Y: float:
	get:
		return -BIRD_OUT_OF_BOUNDS_MARGIN

var BIRD_MAX_Y: float:
	get:
		return SCREEN_HEIGHT + BIRD_OUT_OF_BOUNDS_MARGIN

var PIPE_SPAWN_X: float:
	get:
		return SCREEN_WIDTH + PIPE_SPAWN_MARGIN

var GAP_Y_MAX: float:
	get:
		return GROUND_TOP_Y - GAP_BOTTOM_MARGIN - GAP_SIZE / 2.0

extends Node

const GAME_CONFIG := preload("res://resources/game_config.tres")

var BIRD_START_X: float:
	get:
		return GAME_CONFIG.bird_start_x

var BIRD_IDLE_BOB_AMPLITUDE: float:
	get:
		return GAME_CONFIG.bird_idle_bob_amplitude

var BIRD_OUT_OF_BOUNDS_MARGIN: float:
	get:
		return GAME_CONFIG.bird_out_of_bounds_margin

var GROUND_HEIGHT: float:
	get:
		return GAME_CONFIG.ground_height

var GROUND_GRASS_HEIGHT: float:
	get:
		return GAME_CONFIG.ground_grass_height

var GRAVITY: float:
	get:
		return GAME_CONFIG.gravity

var FLAP_VELOCITY: float:
	get:
		return GAME_CONFIG.flap_velocity

var MAX_FALL_SPEED: float:
	get:
		return GAME_CONFIG.max_fall_speed

var ROTATION_SPEED: float:
	get:
		return GAME_CONFIG.rotation_speed

var PIPE_SPEED: float:
	get:
		return GAME_CONFIG.pipe_speed

var PIPE_WIDTH: float:
	get:
		return GAME_CONFIG.pipe_width

var GAP_SIZE: float:
	get:
		return GAME_CONFIG.gap_size

var PIPE_SPAWN_MARGIN: float:
	get:
		return GAME_CONFIG.pipe_spawn_margin

var GAP_Y_MIN: float:
	get:
		return GAME_CONFIG.gap_y_min

var GAP_BOTTOM_MARGIN: float:
	get:
		return GAME_CONFIG.gap_bottom_margin

var PIPE_SPAWN_INTERVAL: float:
	get:
		return GAME_CONFIG.pipe_spawn_interval

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

extends Node

const BIRD_START_X: float = 120.0
const BIRD_IDLE_BOB_AMPLITUDE: float = 10.0
const BIRD_OUT_OF_BOUNDS_MARGIN: float = 50.0

# Ground
const GROUND_HEIGHT: float = 50.0
const GROUND_GRASS_HEIGHT: float = 8.0

# Bird
const GRAVITY: float = 980.0
const FLAP_VELOCITY: float = -330.0
const MAX_FALL_SPEED: float = 600.0
const ROTATION_SPEED: float = 4.0

# Pipes
const PIPE_SPEED: float = 150.0
const PIPE_WIDTH: float = 70.0
const GAP_SIZE: float = 160.0
const PIPE_SPAWN_MARGIN: float = 40.0
const GAP_Y_MIN: float = 150.0
const GAP_BOTTOM_MARGIN: float = 20.0
const PIPE_SPAWN_INTERVAL: float = 1.6

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

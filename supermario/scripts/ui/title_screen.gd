extends Control

var _blink_timer: float = 0.0
var _ready_for_input: bool = false

@onready var _start_label: Label = $StartLabel


func _ready() -> void:
	GameManager.reset_for_title()
	_ready_for_input = false
	# Delay input acceptance to prevent stale input from carrying over
	get_tree().create_timer(0.3).timeout.connect(func() -> void: _ready_for_input = true)


func _process(delta: float) -> void:
	_blink_timer += delta
	_start_label.visible = fmod(_blink_timer, 1.0) < 0.6

	if not _ready_for_input:
		return
	if Input.is_action_just_pressed(&"jump") or Input.is_action_just_pressed(&"pause"):
		_start_game()


func _start_game() -> void:
	_ready_for_input = false
	# GameManager.start_new_game() now owns the full boot flow — it resets
	# run state, swaps to the first level scene, runs the intro, and starts
	# the timer.
	GameManager.start_new_game()

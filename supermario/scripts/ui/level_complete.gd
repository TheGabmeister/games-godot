extends CanvasLayer

const TALLY_SPEED: float = 200.0  # points per second for visual countdown
const POST_TALLY_DELAY: float = 2.0
# Matches SCORE_FORMAT in hud.gd — zero-padded 6-digit score.
const SCORE_FORMAT: String = "%06d"

@export var stage_clear_sound: AudioStream

var _active: bool = false
var _timer: float = 0.0
var _tallying: bool = false
var _tally_done: bool = false

@onready var _label: Label = $Background/Label


func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	EventBus.level_completed.connect(_show)


func _show() -> void:
	_active = true
	_tallying = true
	_tally_done = false
	_timer = 0.0
	visible = true
	_play_sound(stage_clear_sound)
	_update_label()


func _process(delta: float) -> void:
	if not _active:
		return

	if _tallying:
		# Visual time bonus payout already handled by GameManager._on_level_completed
		_timer += delta
		if _timer >= 1.5:
			_tallying = false
			_tally_done = true
			_timer = 0.0

	elif _tally_done:
		_timer += delta
		if _timer >= POST_TALLY_DELAY:
			_active = false
			visible = false
			_go_next()

	_update_label()


func _update_label() -> void:
	_label.text = "LEVEL COMPLETE!\n\nSCORE: " + (SCORE_FORMAT % GameManager.score)


func _go_next() -> void:
	# GameManager.advance_to_next_level() handles both the "next level"
	# and "no more levels → title" cases internally.
	GameManager.advance_to_next_level()


func _play_sound(sound: AudioStream) -> void:
	if sound != null:
		EventBus.sfx_requested.emit(sound)

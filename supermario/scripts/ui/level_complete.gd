extends CanvasLayer

const TALLY_SPEED: float = 200.0  # points per second for visual countdown
const POST_TALLY_DELAY: float = 2.0

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
	_label.text = "LEVEL COMPLETE!\n\nSCORE: %06d" % GameManager.score


func _go_next() -> void:
	# GameManager.advance_to_next_level() handles both the "next level"
	# and "no more levels → title" cases internally.
	GameManager.advance_to_next_level()

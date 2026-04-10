extends CanvasLayer

const DISPLAY_DURATION: float = 3.0

var _timer: float = 0.0
var _active: bool = false



func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	EventBus.game_over.connect(_show)


func _show() -> void:
	_active = true
	_timer = 0.0
	visible = true


func _process(delta: float) -> void:
	if not _active:
		return
	_timer += delta
	if _timer >= DISPLAY_DURATION:
		_active = false
		visible = false
		# title_screen._ready() calls reset_for_title() itself, so we
		# only need to drive the scene transition here.
		GameManager.return_to_title()

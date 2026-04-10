extends RefCounted

## Tracks the lazy-init + vertical tween used by item emergence.
## Items capture their start_y on the first call, then tween up by `height`
## over `duration` seconds. The caller assigns the returned y and reacts to
## `done` to switch into post-emerge behavior.

var done: bool = false
var _initialized: bool = false
var _start_y: float = 0.0
var _timer: float = 0.0


func update(delta: float, current_y: float, duration: float, height: float) -> float:
	if not _initialized:
		_start_y = current_y
		_initialized = true
	_timer += delta
	var t: float = minf(_timer / duration, 1.0)
	if t >= 1.0:
		done = true
	return _start_y - height * t

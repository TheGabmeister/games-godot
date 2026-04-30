extends RefCounted

var collected: bool = false


func try_collect(owner: Node, sound: AudioStream = null) -> bool:
	if collected:
		return false
	collected = true
	if sound:
		EventBus.sfx_requested.emit(sound)
	owner.queue_free()
	return true

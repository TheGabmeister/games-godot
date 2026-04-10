extends Node

## Cutscene autoload — exposes awaitable primitives for coroutine-based cutscenes.
## Lifecycle signals live here (not on EventBus) per spec convention.

var is_playing: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

signal cutscene_started
signal cutscene_finished


func start() -> void:
	is_playing = true
	cutscene_started.emit()


func finish() -> void:
	is_playing = false
	cutscene_finished.emit()


# --- Primitives (all awaitable) ---

func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func move_entity(entity: Node2D, target: Vector2, duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(entity, "position", target, duration)
	await tween.finished


func camera_pan(camera: Camera2D, target: Vector2, duration: float) -> void:
	# Detach camera from following player by making it top_level
	camera.top_level = true
	camera.global_position = camera.get_screen_center_position()
	var tween := create_tween()
	tween.tween_property(camera, "global_position", target, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished


func camera_follow(camera: Camera2D, target: Node2D) -> void:
	# Restore camera to follow its owner
	camera.top_level = false
	camera.position = Vector2.ZERO


func camera_shake(intensity: float, duration: float) -> void:
	EventBus.screen_shake_requested.emit(intensity, duration)
	await wait(duration)


func dialog(lines: PackedStringArray) -> void:
	EventBus.dialog_requested.emit(Array(lines))
	await EventBus.dialog_closed


func sfx(sfx_name: StringName) -> void:
	AudioManager.play_sfx(sfx_name)


func fade_to_black(duration: float = 0.3) -> void:
	var overlay: CanvasLayer = _get_transition_overlay()
	if overlay:
		await overlay.fade_out(duration)
	else:
		await wait(duration)


func fade_from_black(duration: float = 0.3) -> void:
	var overlay: CanvasLayer = _get_transition_overlay()
	if overlay:
		await overlay.fade_in(duration)
	else:
		await wait(duration)


func flash(color: Color, duration: float = 0.15) -> void:
	var overlay: CanvasLayer = _get_transition_overlay()
	if overlay and overlay.has_node("ColorRect"):
		var rect: ColorRect = overlay.get_node("ColorRect")
		rect.material = null
		rect.visible = true
		rect.color = color
		var tween := create_tween()
		tween.tween_property(rect, "color:a", 0.0, duration)
		await tween.finished
		rect.visible = false
	else:
		await wait(duration)


func _get_transition_overlay() -> CanvasLayer:
	return SceneManager._transition_overlay as CanvasLayer

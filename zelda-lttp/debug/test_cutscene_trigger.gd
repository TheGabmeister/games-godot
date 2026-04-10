extends Node2D

## Walk-in trigger that plays a short test cutscene exercising all primitives.

var _played: bool = false


func _ready() -> void:
	var area := Area2D.new()
	area.collision_layer = 128  # Triggers
	area.collision_mask = 2    # Player
	area.monitoring = true
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16, 16)
	shape.shape = rect
	area.add_child(shape)
	add_child(area)
	area.body_entered.connect(_on_body_entered)
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if _played:
		return
	if body is CharacterBody2D and body.collision_layer & 2:
		_played = true
		_play_cutscene(body)


func _play_cutscene(player: Node2D) -> void:
	var cam: Camera2D = player.get_node_or_null("Camera2D")
	if not cam:
		return

	Cutscene.start()
	await Cutscene.wait(0.3)
	await Cutscene.dialog(PackedStringArray([
		"Cutscene test: camera will pan...",
	]))
	await Cutscene.camera_pan(cam, global_position + Vector2(40, 0), 0.4)
	await Cutscene.wait(0.3)
	await Cutscene.camera_shake(1.5, 0.2)
	await Cutscene.dialog(PackedStringArray([
		"Shake done. Returning camera...",
	]))
	await Cutscene.camera_pan(cam, player.global_position, 0.4)
	Cutscene.camera_follow(cam, player)
	await Cutscene.wait(0.2)
	Cutscene.finish()
	queue_redraw()


func _draw() -> void:
	if _played:
		# Dim after use
		draw_rect(Rect2(-8, -8, 16, 16), Color(0.2, 0.2, 0.3, 0.3))
	else:
		# Glowing trigger pad
		draw_rect(Rect2(-8, -8, 16, 16), Color(0.4, 0.3, 0.7, 0.5))
		draw_rect(Rect2(-8, -8, 16, 16), Color(0.6, 0.5, 0.9, 0.7), false, 1.0)

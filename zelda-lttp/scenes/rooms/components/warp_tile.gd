class_name WarpTile extends Area2D
## Glowing floor tile that warps the player to a target room on contact.
## Spawned by RewardPedestal after dungeon completion.

@export var target_room_id: StringName = &""
@export var target_entry_point: StringName = &""


func _ready() -> void:
	collision_layer = 128  # Triggers
	collision_mask = 2  # Player
	monitoring = true
	monitorable = false

	if not _has_collision_shape():
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(16, 16)
		shape.shape = rect
		add_child(shape)

	body_entered.connect(_on_body_entered)
	queue_redraw()


func _has_collision_shape() -> bool:
	for child in get_children():
		if child is CollisionShape2D:
			return true
	return false


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.collision_layer & 2:
		if target_room_id != &"":
			EventBus.room_transition_requested.emit(target_room_id, target_entry_point)


func _draw() -> void:
	# Glowing warp circle
	var glow := Color(0.3, 0.8, 1.0, 0.5)
	draw_circle(Vector2.ZERO, 8.0, glow)
	draw_arc(Vector2.ZERO, 6.0, 0, TAU, 12, Color(0.5, 0.9, 1.0, 0.7), 1.5)
	draw_arc(Vector2.ZERO, 3.0, 0, TAU, 8, Color.WHITE * Color(1, 1, 1, 0.6), 1.0)

class_name RewardPedestal extends Node2D
## Phase 5 placeholder for dungeon completion. Phase 9 replaces with a real boss.
## On interact: sets flags, heals player, presents reward item, spawns warp tile.

@export var dungeon_id: StringName = &""
@export var reward_flag: StringName = &""  # e.g. &"pendants/courage"
@export var reward_item: ItemData
@export var persist_id: StringName = &"pedestal"
@export var warp_target_room_id: StringName = &""
@export var warp_target_entry_point: StringName = &""

var _consumed: bool = false


func _ready() -> void:
	# Check persist state
	var room_id := _get_room_id()
	if room_id != &"" and persist_id != &"":
		if GameManager.get_flag("%s/%s" % [room_id, persist_id]):
			_consumed = true

	# Create interaction area
	var area := Area2D.new()
	area.collision_layer = 32  # Interactables
	area.collision_mask = 0
	area.monitorable = true
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16, 16)
	shape.shape = rect
	area.add_child(shape)
	add_child(area)

	queue_redraw()


func interact() -> void:
	if _consumed or not reward_item:
		return
	_consumed = true

	# 1. Set reward flag
	if reward_flag != &"":
		GameManager.set_flag(reward_flag, true)

	# 2. Set dungeon completion flag
	if dungeon_id != &"":
		GameManager.set_flag(&"%s/complete" % dungeon_id, true)

	# 3. Fully heal player
	PlayerState.heal(PlayerState.max_health)

	# 4. Persist pedestal as consumed
	var room_id := _get_room_id()
	if room_id != &"" and persist_id != &"":
		GameManager.set_flag("%s/%s" % [room_id, persist_id], true)

	# 5. Present reward item via ItemGetState
	EventBus.item_get_requested.emit(reward_item)

	# 6. After ItemGetState dismisses, spawn warp tile
	await EventBus.dialog_closed
	_spawn_warp_tile()

	queue_redraw()


func _spawn_warp_tile() -> void:
	var warp := WarpTile.new()
	warp.target_room_id = warp_target_room_id
	warp.target_entry_point = warp_target_entry_point
	warp.position = position + Vector2(0, 24)
	get_parent().add_child(warp)


func _get_room_id() -> StringName:
	var node: Node = get_parent()
	while node:
		if "room_data" in node and node.room_data:
			return node.room_data.room_id
		node = node.get_parent()
	return &""


func _draw() -> void:
	if _consumed:
		# Empty pedestal base
		draw_rect(Rect2(-8, -4, 16, 8), Color(0.4, 0.35, 0.3))
		draw_rect(Rect2(-8, -4, 16, 8), Color(0.5, 0.45, 0.4), false, 1.0)
	else:
		# Pedestal base
		draw_rect(Rect2(-8, -4, 16, 8), Color(0.4, 0.35, 0.3))
		draw_rect(Rect2(-8, -4, 16, 8), Color(0.5, 0.45, 0.4), false, 1.0)
		# Reward glow on top
		if reward_item:
			draw_circle(Vector2(0, -8), 5.0, Color(1.0, 0.9, 0.3, 0.6))
			if reward_item.icon_shape.size() > 0:
				var points := PackedVector2Array()
				for p in reward_item.icon_shape:
					points.append(p + Vector2(0, -8))
				draw_colored_polygon(points, reward_item.icon_color)
			else:
				draw_circle(Vector2(0, -8), 3.0, reward_item.icon_color)
		else:
			draw_circle(Vector2(0, -8), 4.0, Color(0.8, 0.7, 0.2))


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if dungeon_id == &"":
		warnings.append("dungeon_id is empty.")
	if reward_flag == &"":
		warnings.append("reward_flag is empty.")
	if not reward_item:
		warnings.append("No reward_item set.")
	if persist_id == &"":
		warnings.append("persist_id is empty.")
	return warnings

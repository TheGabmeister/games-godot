extends BasePlayerState
## Player carries a lifted object above their head. Reduced speed, no sword.

var drop_table: LootTable = null
var visual_type: StringName = &"pot"
var visual_color: Color = Color(0.5, 0.4, 0.3)
var persist_id: StringName = &""
var room_id: StringName = &""
var _carried_visual: Node2D = null
var _stashed_object: Node2D = null  # The hidden destructible, restored on drop

const CARRY_SPEED_MULT := 0.5


func enter(msg: Dictionary = {}) -> void:
	super.enter(msg)
	drop_table = msg.get("drop_table", null)
	visual_type = msg.get("visual_type", &"pot")
	visual_color = msg.get("visual_color", Color(0.5, 0.4, 0.3))
	persist_id = msg.get("persist_id", &"")
	room_id = msg.get("room_id", &"")
	_stashed_object = msg.get("stashed_object", null)

	# Create a visual node above the player
	_carried_visual = Node2D.new()
	_carried_visual.name = "CarriedObject"
	_carried_visual.position = Vector2(0, -16)
	_carried_visual.set_script(load("res://scenes/objects/carried_visual.gd"))
	_carried_visual.set("visual_type", visual_type)
	player.add_child(_carried_visual)


func physics_update(_delta: float) -> void:
	if is_gameplay_paused():
		return
	var input := get_movement_input()
	if input != Vector2.ZERO:
		player.update_facing(input)
		player.velocity = input * player.speed * CARRY_SPEED_MULT
	else:
		player.velocity = Vector2.ZERO
	player.move_and_slide()

	# Check screen-edge transitions — drop the object during transition
	_check_screen_edge_drop()


func handle_input(event: InputEvent) -> void:
	if is_gameplay_paused():
		return
	# Throw on sword or item button
	if event.is_action_pressed("action_sword") or event.is_action_pressed("action_item"):
		# Free the stashed object — it's being thrown, not dropped
		_free_stashed_object()
		state_machine.transition_to(&"Throw", {
			"drop_table": drop_table,
			"visual_type": visual_type,
			"visual_color": visual_color,
			"persist_id": persist_id,
			"room_id": room_id,
		})


func _check_screen_edge_drop() -> void:
	if SceneManager._is_transitioning:
		return
	if not SceneManager.current_room_data:
		return
	if SceneManager.current_room_data.room_type != &"overworld":
		return

	var pos := player.global_position
	var direction := &""
	var scroll_dir := Vector2.ZERO

	if pos.x < 0:
		direction = &"left"
		scroll_dir = Vector2.LEFT
	elif pos.x > SceneManager.SCREEN_WIDTH:
		direction = &"right"
		scroll_dir = Vector2.RIGHT
	elif pos.y < 0:
		direction = &"up"
		scroll_dir = Vector2.UP
	elif pos.y > SceneManager.SCREEN_HEIGHT:
		direction = &"down"
		scroll_dir = Vector2.DOWN

	if direction == &"":
		return

	# Drop the carried object back into the world, then transition
	_drop_object_to_world()

	var room := SceneManager.current_room
	if room and room.has_method("get_neighbor"):
		var neighbor_id: StringName = room.get_neighbor(direction)
		if neighbor_id != &"":
			SceneManager.scroll_to_room(neighbor_id, scroll_dir)


## Restore the stashed destructible at the player's feet and go to Idle.
func _drop_object_to_world() -> void:
	if _stashed_object and is_instance_valid(_stashed_object):
		_stashed_object.global_position = player.global_position + Vector2(0, 8)
		_stashed_object.visible = true
		# Re-enable collisions (deferred since we disabled them deferred)
		_stashed_object.collision_layer = 1
		for child in _stashed_object.get_children():
			if child is Area2D:
				if child.name == "InteractArea" or child.name == "DestructHurtbox":
					child.collision_layer = 32 if child.name == "InteractArea" else 4
					child.monitorable = true
			if child is CollisionShape2D:
				child.disabled = false
		_stashed_object = null
	state_machine.transition_to(&"Idle")


## Free the stashed object (used when throwing — the ThrownObject replaces it).
func _free_stashed_object() -> void:
	if _stashed_object and is_instance_valid(_stashed_object):
		_stashed_object.queue_free()
		_stashed_object = null


func exit() -> void:
	if _carried_visual and is_instance_valid(_carried_visual):
		_carried_visual.queue_free()
		_carried_visual = null
	# Safety: if we exit without explicitly dropping or throwing, drop back
	if _stashed_object and is_instance_valid(_stashed_object):
		_stashed_object.global_position = player.global_position + Vector2(0, 8)
		_stashed_object.visible = true
		_stashed_object.collision_layer = 1
		for child in _stashed_object.get_children():
			if child is Area2D:
				if child.name == "InteractArea" or child.name == "DestructHurtbox":
					child.collision_layer = 32 if child.name == "InteractArea" else 4
					child.monitorable = true
			if child is CollisionShape2D:
				child.disabled = false
		_stashed_object = null

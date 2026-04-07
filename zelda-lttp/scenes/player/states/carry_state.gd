extends BasePlayerState
## Player carries a lifted object above their head. Reduced speed, no sword.

var drop_table: LootTable = null
var visual_type: StringName = &"pot"
var visual_color: Color = Color(0.5, 0.4, 0.3)
var _carried_visual: Node2D = null

const CARRY_SPEED_MULT := 0.5


func enter(msg: Dictionary = {}) -> void:
	super.enter(msg)
	drop_table = msg.get("drop_table", null)
	visual_type = msg.get("visual_type", &"pot")
	visual_color = msg.get("visual_color", Color(0.5, 0.4, 0.3))

	# Create a visual node above the player
	_carried_visual = Node2D.new()
	_carried_visual.name = "CarriedObject"
	_carried_visual.position = Vector2(0, -16)
	_carried_visual.set_script(load("res://scenes/objects/carried_visual.gd"))
	_carried_visual.set("visual_type", visual_type)
	player.add_child(_carried_visual)


func physics_update(delta: float) -> void:
	if is_gameplay_paused():
		return
	var input := get_movement_input()
	if input != Vector2.ZERO:
		player.update_facing(input)
		player.velocity = input * player.speed * CARRY_SPEED_MULT
	else:
		player.velocity = Vector2.ZERO
	player.move_and_slide()


func handle_input(event: InputEvent) -> void:
	if is_gameplay_paused():
		return
	# Throw on sword or item button
	if event.is_action_pressed("action_sword") or event.is_action_pressed("action_item"):
		state_machine.transition_to(&"Throw", {
			"drop_table": drop_table,
			"visual_type": visual_type,
			"visual_color": visual_color,
		})


func exit() -> void:
	if _carried_visual and is_instance_valid(_carried_visual):
		_carried_visual.queue_free()
		_carried_visual = null

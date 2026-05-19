extends CharacterBody2D

enum Dir { DOWN, UP, LEFT, RIGHT }

const DIR_VECTORS := {
	Dir.DOWN:  Vector2.DOWN,
	Dir.UP:    Vector2.UP,
	Dir.LEFT:  Vector2.LEFT,
	Dir.RIGHT: Vector2.RIGHT,
}

const ANIM := {
	Dir.DOWN:  { idle = &"idle_down",  walk = &"walk_down" },
	Dir.UP:    { idle = &"idle_up",    walk = &"walk_up" },
	Dir.LEFT:  { idle = &"idle_left",  walk = &"walk_left" },
	Dir.RIGHT: { idle = &"idle_right", walk = &"walk_right" },
}

@export var speed: float = 200.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interact_area: Area2D = $InteractArea

var facing: Dir = Dir.DOWN

func _physics_process(_delta: float) -> void:
	if not GameState.is_state(GameState.State.FIELD):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var input := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)

	if input.length() > 0:
		input = input.normalized()
		velocity = input * speed
		_update_facing(input)
		sprite.play(ANIM[facing].walk)
	else:
		velocity = Vector2.ZERO
		sprite.play(ANIM[facing].idle)

	move_and_slide()

func _input(event: InputEvent) -> void:
	if not GameState.is_state(GameState.State.FIELD):
		return
	if event.is_action_pressed("confirm"):
		var npc := _get_facing_npc()
		if npc:
			_start_dialogue(npc)
			get_viewport().set_input_as_handled()

func _update_facing(dir: Vector2) -> void:
	if absf(dir.x) > absf(dir.y):
		facing = Dir.RIGHT if dir.x > 0 else Dir.LEFT
	else:
		facing = Dir.DOWN if dir.y > 0 else Dir.UP

func _get_facing_npc() -> Node:
	var face_dir: Vector2 = DIR_VECTORS[facing]
	var best_npc: Node = null
	var best_dot := -1.0
	for area: Area2D in interact_area.get_overlapping_areas():
		if not area.is_in_group("npc_interaction"):
			continue
		var npc: Node = area.get_parent()
		var to_npc: Vector2 = (npc.global_position - global_position).normalized()
		var dot: float = face_dir.dot(to_npc)
		if dot > best_dot:
			best_dot = dot
			best_npc = npc
	return best_npc

func _start_dialogue(npc: Node) -> void:
	GameState.transition(GameState.State.DIALOGUE)
	velocity = Vector2.ZERO
	sprite.play(ANIM[facing].idle)
	var dialogue_box: Node = get_tree().get_first_node_in_group("dialogue_box")
	if dialogue_box:
		dialogue_box.start(npc.npc_name, npc.dialogue)
		dialogue_box.dialogue_finished.connect(_on_dialogue_finished, CONNECT_ONE_SHOT)

func _on_dialogue_finished() -> void:
	GameState.transition(GameState.State.FIELD)

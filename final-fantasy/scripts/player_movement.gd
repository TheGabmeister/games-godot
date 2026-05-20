extends CharacterBody2D

enum Dir { DOWN, UP, LEFT, RIGHT }

const DIR_VECTORS: Dictionary[Dir, Vector2] = {
	Dir.DOWN:  Vector2.DOWN,
	Dir.UP:    Vector2.UP,
	Dir.LEFT:  Vector2.LEFT,
	Dir.RIGHT: Vector2.RIGHT,
}

const IDLE_ANIM: Dictionary[Dir, StringName] = {
	Dir.DOWN:  &"idle_down",
	Dir.UP:    &"idle_up",
	Dir.LEFT:  &"idle_left",
	Dir.RIGHT: &"idle_right",
}

const WALK_ANIM: Dictionary[Dir, StringName] = {
	Dir.DOWN:  &"walk_down",
	Dir.UP:    &"walk_up",
	Dir.LEFT:  &"walk_left",
	Dir.RIGHT: &"walk_right",
}

const FOOTSTEP_STONE := preload("res://ui/footstep_stone.ogg")
const FOOTSTEP_GRASS := preload("res://ui/footstep_grass.ogg")
const FOOTSTEP_INTERVAL := 0.35
const FOOTSTEP_VOLUME := -6.0

@export var speed: float = 200.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interact_area: Area2D = $InteractArea
var facing: Dir = Dir.DOWN
var _footstep_timer := 0.0

func _physics_process(delta: float) -> void:
	if not GameState.is_state(GameState.State.FIELD):
		velocity = Vector2.ZERO
		var _c := move_and_slide()
		return

	var input := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)

	if input.length() > 0:
		input = input.normalized()
		velocity = input * speed
		_update_facing(input)
		sprite.play(WALK_ANIM[facing])
		_footstep_timer -= delta
		if _footstep_timer <= 0.0:
			SfxManager.play(FOOTSTEP_STONE, FOOTSTEP_VOLUME)
			_footstep_timer = FOOTSTEP_INTERVAL
	else:
		velocity = Vector2.ZERO
		sprite.play(IDLE_ANIM[facing])
		_footstep_timer = 0.0

	var _collided := move_and_slide()

func _input(event: InputEvent) -> void:
	if not GameState.is_state(GameState.State.FIELD):
		return
	if event.is_action_pressed("menu"):
		velocity = Vector2.ZERO
		sprite.play(IDLE_ANIM[facing])
		GameState.transition(GameState.State.MENU)
		var menu_node := get_tree().get_first_node_in_group(Groups.MAIN_MENU)
		if menu_node:
			menu_node.call(&"open")
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("confirm"):
		var target := _get_facing_interactable()
		if target:
			velocity = Vector2.ZERO
			sprite.play(IDLE_ANIM[facing])
			target.call(&"interact")
			get_viewport().set_input_as_handled()

func _update_facing(dir: Vector2) -> void:
	if absf(dir.x) > absf(dir.y):
		facing = Dir.RIGHT if dir.x > 0 else Dir.LEFT
	else:
		facing = Dir.DOWN if dir.y > 0 else Dir.UP

func _get_facing_interactable() -> Node2D:
	var face_dir: Vector2 = DIR_VECTORS[facing]
	var best_target: Node2D = null
	var best_dot := -1.0
	for area: Area2D in interact_area.get_overlapping_areas():
		if not area.is_in_group(Groups.INTERACTABLE):
			continue
		var parent := area.get_parent()
		if parent is Node2D:
			var target: Node2D = parent
			var to_target: Vector2 = (target.global_position - global_position).normalized()
			var dot: float = face_dir.dot(to_target)
			if dot > best_dot:
				best_dot = dot
				best_target = target
	return best_target

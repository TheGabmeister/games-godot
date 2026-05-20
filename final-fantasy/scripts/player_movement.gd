class_name PlayerMovement
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
const TILE_SIZE := 64.0

signal encounter_triggered(formation: EncounterFormation)

@export var speed: float = 200.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interact_area: Area2D = $InteractArea
var facing: Dir = Dir.DOWN
var _footstep_timer := 0.0

var encounter_table: EncounterTable
var _step_accumulator := 0.0
var _step_count := 0
var _steps_to_encounter := 0

func _ready() -> void:
	reset_step_counter()

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
		_count_steps(delta)
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
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("confirm"):
		var target := _get_facing_interactable()
		if target:
			velocity = Vector2.ZERO
			sprite.play(IDLE_ANIM[facing])
			target.call(&"interact")
			get_viewport().set_input_as_handled()

func _count_steps(delta: float) -> void:
	if not encounter_table:
		return
	_step_accumulator += velocity.length() * delta
	while _step_accumulator >= TILE_SIZE:
		_step_accumulator -= TILE_SIZE
		_step_count += 1
		if _step_count >= _steps_to_encounter:
			velocity = Vector2.ZERO
			sprite.play(IDLE_ANIM[facing])
			var formation := _pick_formation()
			reset_step_counter()
			encounter_triggered.emit(formation)
			return

func reset_step_counter() -> void:
	_step_count = 0
	_step_accumulator = 0.0
	if encounter_table:
		_steps_to_encounter = randi_range(encounter_table.steps_min, encounter_table.steps_max)

func _pick_formation() -> EncounterFormation:
	var total_weight := 0
	for f: EncounterFormation in encounter_table.formations:
		total_weight += f.weight
	var roll := randi_range(1, total_weight)
	var accum := 0
	for f: EncounterFormation in encounter_table.formations:
		accum += f.weight
		if roll <= accum:
			return f
	return encounter_table.formations.back()

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

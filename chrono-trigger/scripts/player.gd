extends CharacterBody2D

const SPEED := 150.0
const RAY_LENGTH := 20.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interact_ray: RayCast2D = $InteractRay

var facing := Vector2.DOWN

func _ready() -> void:
	_load_runtime_sprite_frames()
	_play_idle_animation()

func _physics_process(_delta: float) -> void:
	if GameState.current != GameState.State.FIELD:
		velocity = Vector2.ZERO
		return

	var input := Vector2.ZERO
	input.x = Input.get_axis("move_left", "move_right")
	input.y = Input.get_axis("move_up", "move_down")
	input = input.normalized()

	velocity = input * SPEED

	if input != Vector2.ZERO:
		facing = input.snapped(Vector2.ONE).normalized()
		interact_ray.target_position = facing * RAY_LENGTH
		_play_walk_animation()
	else:
		_play_idle_animation()

	move_and_slide()

	if Input.is_action_just_pressed("interact"):
		_try_interact()

func _play_walk_animation() -> void:
	var anim := _direction_name()
	animated_sprite.play("walk_" + anim)

func _play_idle_animation() -> void:
	var anim := _direction_name()
	animated_sprite.play("idle_" + anim)

func _direction_name() -> String:
	if abs(facing.x) > abs(facing.y):
		return "right" if facing.x > 0 else "left"
	else:
		return "down" if facing.y > 0 else "up"

func get_facing_direction_name() -> String:
	return _direction_name()

func _try_interact() -> void:
	if not interact_ray.is_colliding():
		return
	var collider := interact_ray.get_collider()
	if collider and collider.is_in_group("interactable"):
		collider.interact()

func _load_runtime_sprite_frames() -> void:
	var image := Image.load_from_file("res://player/crono_sheet.png")
	if image == null or image.is_empty():
		return

	var texture := ImageTexture.create_from_image(image)
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")

	_add_sheet_animation(frames, texture, "idle_down", [0], 1.0, true)
	_add_sheet_animation(frames, texture, "idle_up", [2], 1.0, true)
	_add_sheet_animation(frames, texture, "idle_left", [4], 1.0, true)
	_add_sheet_animation(frames, texture, "idle_right", [6], 1.0, true)
	_add_sheet_animation(frames, texture, "walk_down", [0, 1], 6.0, true)
	_add_sheet_animation(frames, texture, "walk_up", [2, 3], 6.0, true)
	_add_sheet_animation(frames, texture, "walk_left", [4, 5], 6.0, true)
	_add_sheet_animation(frames, texture, "walk_right", [6, 7], 6.0, true)
	if image.get_width() >= 768:
		_add_sheet_animation(frames, texture, "attack_down", [8], 1.0, false)
		_add_sheet_animation(frames, texture, "attack_up", [9], 1.0, false)
		_add_sheet_animation(frames, texture, "attack_left", [10], 1.0, false)
		_add_sheet_animation(frames, texture, "attack_right", [11], 1.0, false)

	animated_sprite.sprite_frames = frames

func _add_sheet_animation(frames: SpriteFrames, texture: Texture2D, animation_name: String, frame_indexes: Array, speed: float, loop: bool) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, speed)
	frames.set_animation_loop(animation_name, loop)
	for frame_index in frame_indexes:
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(int(frame_index) * 64, 0, 64, 64)
		frames.add_frame(animation_name, atlas)

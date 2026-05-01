extends Area2D

@export var data: Resource

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var battle_started := false

func _ready() -> void:
	_load_runtime_sprite_frames()
	body_entered.connect(_on_body_entered)
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("idle"):
		animated_sprite.play("idle")

func _on_body_entered(body: Node2D) -> void:
	if battle_started:
		return
	if GameState.current != GameState.State.FIELD:
		return
	if not body is CharacterBody2D:
		return

	var battle_manager := get_node_or_null("/root/DebugRoom/BattleManager")
	if battle_manager == null:
		return

	battle_started = true
	monitoring = false
	battle_manager.start_battle(self)

func set_battle_collision_enabled(enabled: bool) -> void:
	collision_shape.set_deferred("disabled", not enabled)

func play_idle() -> void:
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("idle"):
		animated_sprite.play("idle")

func play_attack() -> void:
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("attack"):
		animated_sprite.play("attack")

func play_hit() -> void:
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("hit"):
		animated_sprite.play("hit")

func play_die() -> void:
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("die"):
		animated_sprite.play("die")

func _load_runtime_sprite_frames() -> void:
	var image := Image.load_from_file("res://enemies/imp_sheet.png")
	if image == null or image.is_empty():
		return

	var texture := ImageTexture.create_from_image(image)
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")

	_add_sheet_animation(frames, texture, "idle", [0, 1], 3.0, true)
	_add_sheet_animation(frames, texture, "attack", [2], 1.0, false)
	_add_sheet_animation(frames, texture, "hit", [3], 1.0, false)
	_add_sheet_animation(frames, texture, "die", [4, 5], 4.0, false)
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

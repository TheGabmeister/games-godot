extends RefCounted

const CELL_SIZE := 32


static func build(texture: Texture2D, columns: int, animations: Dictionary) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")

	for anim_name: StringName in animations:
		var config: Dictionary = animations[anim_name]
		var indices: Array = config["frames"]
		var fps: float = config.get("fps", 8.0)
		var loop: bool = config.get("loop", true)

		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, fps)
		frames.set_animation_loop(anim_name, loop)

		for idx: int in indices:
			var col := idx % columns
			@warning_ignore("integer_division")
			var row := idx / columns
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(col * CELL_SIZE, row * CELL_SIZE, CELL_SIZE, CELL_SIZE)
			frames.add_frame(anim_name, atlas)

	return frames


static func ensure_sprite(
	parent: Node,
	node_name: StringName,
	texture: Texture2D,
	columns: int,
	animations: Dictionary,
	animation: StringName = &"default"
) -> AnimatedSprite2D:
	var sprite := parent.get_node_or_null(NodePath(node_name)) as AnimatedSprite2D
	if sprite == null:
		sprite = AnimatedSprite2D.new()
		sprite.name = node_name
		parent.add_child(sprite)
	sprite.sprite_frames = build(texture, columns, animations)
	sprite.animation = animation
	sprite.centered = false
	return sprite

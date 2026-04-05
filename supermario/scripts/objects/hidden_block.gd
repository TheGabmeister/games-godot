extends StaticBody2D

# Classic SMB hidden block:
# - Invisible with no collision until struck from below while moving upward.
# - On first valid hit, reveals, enables collision, spawns contents, and
#   behaves thereafter as an inert empty brown block.
#
# We can't use the shared `check_ceiling_bumps()` pattern because the block
# starts with collision disabled, so slide collisions never report it. Instead
# a child Area2D on the Player layer detects the pass-through and triggers the
# reveal. After reveal the block's StaticBody2D collision is enabled and it
# participates in normal physics like any other solid block.

const P := preload("res://scripts/color_palette.gd")
const MushroomScene := preload("res://scenes/objects/mushroom.tscn")

@export var contents: StringName = &"coin"  # "coin" or "1up"

var _revealed: bool = false
var _bumping: bool = false
var _bump_time: float = 0.0
var _bump_offset: float = 0.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var trigger_area: Area2D = $TriggerArea


func _ready() -> void:
	collision_layer = 1  # Terrain
	collision_mask = 0
	collision_shape.disabled = true
	trigger_area.body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if _bumping:
		_bump_time += delta
		var t: float = _bump_time / 0.15
		if t >= 1.0:
			_bump_offset = 0.0
			_bumping = false
		else:
			_bump_offset = -4.0 * sin(t * PI)
		queue_redraw()


func _draw() -> void:
	if not _revealed:
		return
	var y_off: float = _bump_offset
	# Empty brown block (matches the "used" look of question/brick blocks)
	draw_rect(Rect2(-8, -16 + y_off, 16, 16), P.BLOCK_BROWN)
	draw_rect(Rect2(-8, -16 + y_off, 16, 2), P.BLOCK_BROWN.darkened(0.3))
	draw_rect(Rect2(-8, -2 + y_off, 16, 2), P.BLOCK_BROWN.darkened(0.3))
	draw_rect(Rect2(-8, -16 + y_off, 2, 16), P.BLOCK_BROWN.darkened(0.3))
	draw_rect(Rect2(6, -16 + y_off, 2, 16), P.BLOCK_BROWN.darkened(0.3))


func _on_body_entered(body: Node2D) -> void:
	if _revealed:
		return
	if not body.is_in_group("player"):
		return
	# Only trigger when the player is jumping up into the block from below.
	# Since the block has no collision yet, velocity.y is preserved (not
	# zeroed by move_and_slide) and reflects the jump direction reliably.
	if body.velocity.y >= 0.0:
		return
	_reveal_and_bump()


func _reveal_and_bump() -> void:
	_revealed = true
	# Enable solid collision so the player is stopped on the next physics step.
	collision_shape.set_deferred("disabled", false)
	# Disable the trigger so it can't re-fire or interfere later.
	trigger_area.set_deferred("monitoring", false)
	_bumping = true
	_bump_time = 0.0
	EventBus.block_bumped.emit(global_position)
	queue_redraw()
	_spawn_contents()


func bump_from_below() -> void:
	# Once revealed the block is inert. Exists so the player's
	# check_ceiling_bumps() slide iteration has a valid method to call.
	pass


func _spawn_contents() -> void:
	var spawn_pos: Vector2 = global_position + Vector2(0, -16)
	match contents:
		&"coin":
			GameManager.add_coin(spawn_pos)
			EventBus.item_spawned.emit(&"coin", spawn_pos)
		&"1up":
			# No dedicated 1-UP mushroom scene yet; spawn a regular mushroom
			# so the block is playable. Replace with a green 1-UP variant
			# when one is added.
			var item := MushroomScene.instantiate() as Node2D
			get_parent().add_child(item)
			item.global_position = spawn_pos
			EventBus.item_spawned.emit(&"1up", spawn_pos)
		_:
			push_warning("Unknown hidden block contents: %s" % contents)

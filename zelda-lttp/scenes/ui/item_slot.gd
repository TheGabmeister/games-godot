extends Control

const SLOT_SIZE := 16.0
const FLASH_DURATION := 0.25

var _flash_timer: float = 0.0
var _last_skill_id: StringName = &""


func _ready() -> void:
	custom_minimum_size = Vector2(SLOT_SIZE + 4, SLOT_SIZE + 4)
	_last_skill_id = PlayerState.equipped_skill_id
	EventBus.item_acquired.connect(_on_item_acquired)
	queue_redraw()


func _process(delta: float) -> void:
	# Detect skill switch
	if PlayerState.equipped_skill_id != _last_skill_id:
		_last_skill_id = PlayerState.equipped_skill_id
		_flash_timer = FLASH_DURATION
	if _flash_timer > 0.0:
		_flash_timer -= delta
		queue_redraw()


func _on_item_acquired(_item_id: StringName) -> void:
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2(2, 2), Vector2(SLOT_SIZE, SLOT_SIZE))

	# Highlight flash when switching items
	if _flash_timer > 0.0:
		var t: float = _flash_timer / FLASH_DURATION
		draw_rect(rect, Color(1.0, 1.0, 0.8, 0.5 * t))

	# Box outline
	draw_rect(rect, Color(0.8, 0.8, 0.8, 0.6), false, 1.0)

	# Draw equipped item icon
	var skill: ItemData = PlayerState.get_equipped_skill()
	if skill and skill.icon_shape.size() > 0:
		var offset := Vector2(2 + SLOT_SIZE / 2.0, 2 + SLOT_SIZE / 2.0)
		var points := PackedVector2Array()
		for p in skill.icon_shape:
			points.append(p + offset)
		draw_colored_polygon(points, skill.icon_color)

extends Control

@onready var hearts_display: Control = $HeartsDisplay
@onready var rupee_counter: Control = $RupeeCounter
@onready var item_slot: Control = $ItemSlot
@onready var magic_meter: Control = $MagicMeter


func _ready() -> void:
	EventBus.player_health_changed.connect(_on_health_changed)
	EventBus.player_rupees_changed.connect(_on_rupees_changed)
	EventBus.player_magic_changed.connect(_on_magic_changed)


func _draw() -> void:
	# Semi-transparent dark bar behind hearts/rupees/magic for readability
	draw_rect(Rect2(0, 0, 122, 42), Color(0.0, 0.0, 0.05, 0.35))
	# Item slot background (top-right)
	draw_rect(Rect2(size.x - 28, 0, 28, 28), Color(0.0, 0.0, 0.05, 0.35))


func _on_health_changed(current: int, max_health: int) -> void:
	hearts_display.update_hearts(current, max_health)


func _on_rupees_changed(amount: int) -> void:
	rupee_counter.update_rupees(amount)


func _on_magic_changed(current: int, max_magic: int) -> void:
	magic_meter.update_magic(current, max_magic)

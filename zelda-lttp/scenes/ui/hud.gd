extends Control

@onready var hearts_display: Control = $HeartsDisplay
@onready var rupee_counter: Control = $RupeeCounter
@onready var item_slot: Control = $ItemSlot
@onready var magic_meter: Control = $MagicMeter


func _ready() -> void:
	EventBus.player_health_changed.connect(_on_health_changed)
	EventBus.player_rupees_changed.connect(_on_rupees_changed)
	EventBus.player_magic_changed.connect(_on_magic_changed)


func _on_health_changed(current: int, max_health: int) -> void:
	hearts_display.update_hearts(current, max_health)


func _on_rupees_changed(amount: int) -> void:
	rupee_counter.update_rupees(amount)


func _on_magic_changed(current: int, max_magic: int) -> void:
	magic_meter.update_magic(current, max_magic)

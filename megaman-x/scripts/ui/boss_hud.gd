extends Control
class_name BossHUD

var _encounter: Node = null
var _boss_name := "Boss Target"
var _current_health := 0
var _max_health := 0

@onready var name_value: Label = $BossAnchor/Panel/Content/NameValue
@onready var health_value: Label = $BossAnchor/Panel/Content/HealthValue
@onready var health_bar: ProgressBar = $BossAnchor/Panel/Content/HealthBar


func _ready() -> void:
	visible = false
	_refresh_display()


func bind_encounter(encounter: Node) -> void:
	_encounter = encounter
	if _encounter == null:
		visible = false
		return

	if _encounter.has_signal("encounter_started"):
		_encounter.connect("encounter_started", _on_encounter_started)
	if _encounter.has_signal("encounter_ended"):
		_encounter.connect("encounter_ended", _on_encounter_ended)
	if _encounter.has_signal("boss_health_changed"):
		_encounter.connect("boss_health_changed", _on_boss_health_changed)

	if _encounter.has_method("get_boss_display_name"):
		_boss_name = String(_encounter.get_boss_display_name())
	if _encounter.has_method("get_boss_current_health"):
		_current_health = int(_encounter.get_boss_current_health())
	if _encounter.has_method("get_boss_max_health"):
		_max_health = int(_encounter.get_boss_max_health())
	visible = bool(_encounter.has_method("is_encounter_active") and _encounter.is_encounter_active())
	_refresh_display()


func get_snapshot() -> Dictionary:
	return {
		"visible": visible,
		"name_text": name_value.text if name_value != null else "",
		"health_text": health_value.text if health_value != null else "",
		"health_ratio": health_bar.value if health_bar != null else 0.0,
	}


func _on_encounter_started(_boss_id: StringName, display_name: String) -> void:
	_boss_name = display_name
	visible = true
	_refresh_display()


func _on_encounter_ended(_boss_id: StringName, _reason: StringName) -> void:
	visible = false


func _on_boss_health_changed(current_health: int, max_health: int) -> void:
	_current_health = current_health
	_max_health = max_health
	_refresh_display()


func _refresh_display() -> void:
	if name_value == null or health_value == null or health_bar == null:
		return

	name_value.text = _boss_name
	health_value.text = "%d / %d" % [_current_health, _max_health]
	health_bar.value = 0.0 if _max_health <= 0 else (float(_current_health) / float(_max_health)) * 100.0

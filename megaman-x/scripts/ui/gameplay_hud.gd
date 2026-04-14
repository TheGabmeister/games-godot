extends Control
class_name GameplayHUD

var _player: Node = null
var _health_component: Node = null
var _player_combat: PlayerCombat = null

@onready var health_value: Label = $Anchor/PanelRoot/Content/HealthValue
@onready var weapon_value: Label = $Anchor/PanelRoot/Content/WeaponValue
@onready var state_value: Label = $Anchor/PanelRoot/Content/StateValue
@onready var charge_value: Label = $Anchor/PanelRoot/Content/ChargeValue


func bind_player(player: Node) -> void:
	_player = player
	_health_component = null
	_player_combat = null

	if _player != null and _player.has_method("get_health_component"):
		_health_component = _player.get_health_component()
		if _health_component != null:
			_health_component.health_changed.connect(_on_health_changed)

	_player_combat = _player.get_node_or_null("PlayerCombat") as PlayerCombat
	if _player_combat != null:
		_player_combat.weapon_changed.connect(_on_weapon_changed)
		_player_combat.combat_state_changed.connect(_on_combat_state_changed)
		_player_combat.charge_feedback_changed.connect(_on_charge_feedback_changed)

	_refresh_display()


func get_snapshot() -> Dictionary:
	return {
		"health_text": health_value.text,
		"weapon_text": weapon_value.text,
		"state_text": state_value.text,
		"charge_text": charge_value.text,
	}


func _ready() -> void:
	_refresh_display()


func _on_health_changed(_current_health: int, _max_health: int) -> void:
	_refresh_display()


func _on_weapon_changed(_weapon_id: StringName, _display_name: String) -> void:
	_refresh_display()


func _on_combat_state_changed(_previous_state: int, _new_state: int) -> void:
	_refresh_display()


func _on_charge_feedback_changed(_previous_feedback: int, _new_feedback: int) -> void:
	_refresh_display()


func _refresh_display() -> void:
	if health_value == null:
		return

	if _health_component != null:
		health_value.text = "%d / %d" % [_health_component.current_health, _health_component.max_health]
	else:
		health_value.text = "-- / --"

	if _player_combat != null:
		weapon_value.text = _player_combat.get_current_weapon_name()
		state_value.text = _player_combat.get_combat_state_name()
		charge_value.text = _player_combat.get_charge_feedback_name()
	else:
		weapon_value.text = "Offline"
		state_value.text = "OFFLINE"
		charge_value.text = "none"

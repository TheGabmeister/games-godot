extends CanvasLayer

const LOW_ENERGY_THRESHOLD: int = 29
const ALARM_FLASH_INTERVAL: float = 0.15

@onready var energy_label: Label = $HUDBar/EnergySection/EnergyLabel
@onready var tank_container: HBoxContainer = $HUDBar/EnergySection/TankContainer
@onready var weapon_icon: TextureRect = $HUDBar/WeaponSection/WeaponIcon
@onready var ammo_label: Label = $HUDBar/WeaponSection/AmmoLabel
@onready var weapon_section: Control = $HUDBar/WeaponSection

var _alarm_active: bool = false
var _alarm_timer: float = 0.0
var _alarm_beep: AudioStream = preload("res://player/audio/alarm_beep.ogg")
var _icon_beam: Texture2D = preload("res://hud/sprites/icon_beam.png")
var _icon_missile: Texture2D = preload("res://hud/sprites/icon_missile.png")
var _pip_full: Texture2D = preload("res://hud/sprites/tank_pip_full.png")
var _pip_empty: Texture2D = preload("res://hud/sprites/tank_pip_empty.png")


func _process(delta: float) -> void:
	if _alarm_active:
		_alarm_timer += delta
		if fmod(_alarm_timer, ALARM_FLASH_INTERVAL * 2.0) < ALARM_FLASH_INTERVAL:
			energy_label.modulate.a = 0.2
		else:
			energy_label.modulate.a = 1.0


func connect_to_player(player: Player) -> void:
	var _e1 := player.energy_changed.connect(_on_energy_changed)
	var _e2 := player.ammo_changed.connect(_on_ammo_changed)
	var _e3 := player.weapon_switched.connect(_on_weapon_switched)


func _on_energy_changed(current: int, maximum: int) -> void:
	energy_label.text = "%04d" % current
	_update_tanks(current, maximum)
	if current <= LOW_ENERGY_THRESHOLD and current > 0:
		if not _alarm_active:
			_alarm_active = true
			_alarm_timer = 0.0
			SfxManager.play_loop(&"low_energy", _alarm_beep)
	else:
		if _alarm_active:
			_alarm_active = false
			energy_label.modulate.a = 1.0
			SfxManager.stop_loop(&"low_energy")


func _on_ammo_changed(_weapon: StringName, current: int, _maximum: int) -> void:
	ammo_label.text = "%03d" % current


func _on_weapon_switched(weapon: StringName) -> void:
	match weapon:
		PlayerConsts.WEAPON_BEAM:
			weapon_icon.texture = _icon_beam
			ammo_label.visible = false
		PlayerConsts.WEAPON_MISSILE:
			weapon_icon.texture = _icon_missile
			ammo_label.visible = true


func _update_tanks(current: int, maximum: int) -> void:
	var base_energy := 99
	var tank_count: int = floori(float(maximum - base_energy) / 100.0)
	for child: Node in tank_container.get_children():
		child.queue_free()
	var energy_in_tanks := current - base_energy
	for i: int in tank_count:
		var pip := TextureRect.new()
		pip.stretch_mode = TextureRect.STRETCH_KEEP
		if energy_in_tanks >= (i + 1) * 100:
			pip.texture = _pip_full
		else:
			pip.texture = _pip_empty
		tank_container.add_child(pip)

extends Node2D
class_name ChillPenguinBoss

const HIT_PAYLOAD_SCRIPT = preload("res://scripts/components/hit_payload.gd")

signal phase_changed(previous_phase: StringName, new_phase: StringName)
signal attack_fired(phase: StringName, attack_id: StringName)
signal boss_defeated

const PHASE_WAITING := &"WAITING"
const PHASE_INTRO := &"INTRO"
const PHASE_ONE := &"PHASE_ONE"
const PHASE_TWO := &"PHASE_TWO"
const PHASE_DEFEATED := &"DEFEATED"

@export var player_path: NodePath
@export var projectile_scene: PackedScene
@export var intro_duration := 0.65
@export var phase_one_speed := 58.0
@export var phase_two_speed := 86.0
@export var phase_one_attack_interval := 1.35
@export var phase_two_attack_interval := 0.9
@export var phase_two_burst_count := 2
@export var phase_two_burst_spacing := 0.18
@export var patrol_distance := 132.0
@export var projectile_damage := 2
@export var projectile_speed := 220.0
@export var projectile_lifetime := 1.4
@export var projectile_knockback := Vector2(135.0, -70.0)
@export var contact_damage := 4
@export var contact_knockback := Vector2(180.0, -110.0)

@onready var health_component: Node = $HealthComponent
@onready var hurtbox: Area2D = $Hurtbox
@onready var contact_area: Area2D = $ContactArea
@onready var visual_root: Node2D = $VisualRoot
@onready var phase_label: Label = $VisualRoot/PhaseLabel
@onready var status_label: Label = $VisualRoot/StatusLabel
@onready var attack_origin: Marker2D = $AttackOrigin
@onready var player: Node = get_node_or_null(player_path)

var _spawn_position := Vector2.ZERO
var _phase: StringName = PHASE_WAITING
var _is_active := false
var _boss_enabled := true
var _attack_timer := 0.0
var _burst_shots_remaining := 0
var _burst_delay_remaining := 0.0
var _move_direction := -1


func _ready() -> void:
	add_to_group(&"stage_resettable")
	_spawn_position = global_position
	if health_component != null:
		health_component.connect("health_changed", _on_health_changed)
		health_component.connect("died", _on_health_component_died)
	reset_for_stage_retry()
	if contact_area != null:
		contact_area.area_entered.connect(_on_contact_area_area_entered)


func _physics_process(delta: float) -> void:
	if not _is_active:
		return

	if _phase == PHASE_INTRO:
		_attack_timer = maxf(_attack_timer - delta, 0.0)
		if _attack_timer == 0.0:
			_set_phase(PHASE_ONE)
			_reset_attack_timers_for_phase()
		return

	if _phase != PHASE_ONE and _phase != PHASE_TWO:
		return

	_update_movement(delta)
	_update_attacks(delta)


func get_health_component() -> Node:
	return health_component


func set_boss_enabled(is_enabled: bool) -> void:
	_boss_enabled = is_enabled
	visible = is_enabled
	_is_active = false
	_burst_shots_remaining = 0
	_burst_delay_remaining = 0.0
	if hurtbox != null:
		hurtbox.monitorable = is_enabled
	if contact_area != null:
		contact_area.monitoring = is_enabled
	if not is_enabled:
		_phase = PHASE_WAITING
		_refresh_visuals()


func get_phase_name() -> StringName:
	return _phase


func get_debug_summary() -> String:
	return "%s | HP %d/%d" % [
		_phase,
		int(health_component.get("current_health")) if health_component != null else 0,
		int(health_component.get("max_health")) if health_component != null else 0,
	]


func on_encounter_started() -> void:
	if not _boss_enabled:
		return
	if _phase == PHASE_DEFEATED:
		return

	_is_active = true
	_burst_shots_remaining = 0
	_burst_delay_remaining = 0.0
	_set_phase(PHASE_INTRO)
	_attack_timer = intro_duration


func reset_for_stage_retry() -> void:
	global_position = _spawn_position
	_is_active = false
	_attack_timer = 0.0
	_burst_shots_remaining = 0
	_burst_delay_remaining = 0.0
	_move_direction = -1
	visible = _boss_enabled
	if hurtbox != null:
		hurtbox.monitorable = _boss_enabled
	if contact_area != null:
		contact_area.monitoring = _boss_enabled
	if health_component != null:
		health_component.call("reset")
	_phase = PHASE_WAITING
	_refresh_visuals()


func _set_phase(new_phase: StringName) -> void:
	if _phase == new_phase:
		return

	var previous_phase := _phase
	_phase = new_phase
	_refresh_visuals()
	phase_changed.emit(previous_phase, _phase)


func _refresh_visuals() -> void:
	if phase_label != null:
		phase_label.text = String(_phase)
	if status_label != null:
		status_label.text = get_debug_summary()
	if visual_root == null:
		return

	match _phase:
		PHASE_TWO:
			visual_root.modulate = Color(0.95, 0.86, 1.0, 1.0)
		PHASE_DEFEATED:
			visual_root.modulate = Color(0.62, 0.62, 0.7, 1.0)
		_:
			visual_root.modulate = Color(1.0, 1.0, 1.0, 1.0)


func _update_movement(delta: float) -> void:
	if player != null:
		var delta_x := player.global_position.x - global_position.x
		if absf(delta_x) > 8.0:
			_move_direction = 1 if delta_x > 0.0 else -1

	var speed := phase_one_speed if _phase == PHASE_ONE else phase_two_speed
	global_position.x = clampf(
		global_position.x + float(_move_direction) * speed * delta,
		_spawn_position.x - patrol_distance,
		_spawn_position.x + patrol_distance
	)
	if visual_root != null:
		visual_root.scale.x = -1.0 if _move_direction < 0 else 1.0


func _update_attacks(delta: float) -> void:
	if _burst_shots_remaining > 0:
		_burst_delay_remaining = maxf(_burst_delay_remaining - delta, 0.0)
		if _burst_delay_remaining == 0.0:
			_fire_ice_shot()
			_burst_shots_remaining -= 1
			if _burst_shots_remaining > 0:
				_burst_delay_remaining = phase_two_burst_spacing
			else:
				_reset_attack_timers_for_phase()
		return

	_attack_timer = maxf(_attack_timer - delta, 0.0)
	if _attack_timer > 0.0:
		return

	if _phase == PHASE_TWO:
		_burst_shots_remaining = maxi(phase_two_burst_count - 1, 0)
		_fire_ice_shot()
		if _burst_shots_remaining > 0:
			_burst_delay_remaining = phase_two_burst_spacing
		else:
			_reset_attack_timers_for_phase()
	else:
		_fire_ice_shot()
		_reset_attack_timers_for_phase()


func _reset_attack_timers_for_phase() -> void:
	_attack_timer = phase_one_attack_interval if _phase == PHASE_ONE else phase_two_attack_interval


func _fire_ice_shot() -> void:
	if projectile_scene == null or attack_origin == null:
		return

	var projectile := projectile_scene.instantiate()
	var projectile_parent := get_parent()
	if projectile_parent == null:
		projectile.queue_free()
		return

	projectile_parent.add_child(projectile)
	projectile.global_position = attack_origin.global_position
	var shot_direction := _move_direction
	if player != null:
		shot_direction = 1 if player.global_position.x >= global_position.x else -1
	if projectile.has_method("configure"):
		projectile.configure({
			"team": &"enemy",
			"weapon_id": &"chill_penguin_ice",
			"damage": projectile_damage,
			"direction": shot_direction,
			"speed": projectile_speed,
			"lifetime": projectile_lifetime,
			"color": Color(0.67, 0.92, 1.0, 1.0),
			"visual_scale": Vector2(1.0, 1.0),
			"knockback": projectile_knockback,
		})
	attack_fired.emit(_phase, &"ice_shot")


func _on_health_changed(current_health: int, max_health: int) -> void:
	_refresh_visuals()
	if not _is_active or _phase != PHASE_ONE:
		return
	if current_health <= maxi(1, int(ceil(float(max_health) * 0.5))):
		_set_phase(PHASE_TWO)
		_burst_shots_remaining = 0
		_burst_delay_remaining = 0.0
		_reset_attack_timers_for_phase()


func _on_health_component_died() -> void:
	_is_active = false
	_set_phase(PHASE_DEFEATED)
	visible = false
	if hurtbox != null:
		hurtbox.set_deferred("monitorable", false)
	if contact_area != null:
		contact_area.set_deferred("monitoring", false)
	boss_defeated.emit()


func _on_contact_area_area_entered(area: Area2D) -> void:
	if not _is_active or _phase == PHASE_WAITING or _phase == PHASE_DEFEATED:
		return
	if area == null or not area.has_method("apply_hit_payload"):
		return

	var x_direction := 1.0
	if area.global_position.x < global_position.x:
		x_direction = -1.0

	var payload := HIT_PAYLOAD_SCRIPT.create(
		self,
		&"enemy",
		&"chill_penguin_body",
		contact_damage,
		Vector2(absf(contact_knockback.x) * x_direction, contact_knockback.y)
	)
	area.apply_hit_payload(payload)

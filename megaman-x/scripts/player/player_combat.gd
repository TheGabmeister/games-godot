extends Node
class_name PlayerCombat

enum CombatState {
	READY,
	FIRING,
	CHARGING,
	CHARGED,
	COOLDOWN,
	DISABLED,
}

enum ChargeFeedback {
	NONE,
	SMALL,
	FULL,
}

signal combat_state_changed(previous_state: int, new_state: int)
signal charge_feedback_changed(previous_feedback: int, new_feedback: int)
signal weapon_changed(weapon_id: StringName, display_name: String)
signal weapon_energy_changed(weapon_id: StringName, current_energy: int, max_energy: int)
signal projectile_spawned(projectile: Node, spawn_position: Vector2, tier: StringName)
signal shot_fired(weapon_id: StringName, tier: StringName)
signal combat_enabled_changed(is_enabled: bool)

const FIRE_STATE_DURATION := 0.04

@onready var player: Node = get_parent()
@onready var shot_origin: Marker2D = get_node_or_null("../ShotOrigin") as Marker2D
@onready var weapon_inventory: WeaponInventory = $WeaponInventory as WeaponInventory

var combat_enabled := true
var combat_state: int = CombatState.READY
var charge_feedback: int = ChargeFeedback.NONE

var _charge_elapsed := 0.0
var _cooldown_remaining := 0.0
var _fire_state_remaining := 0.0
var _tracked_projectiles: Array[Node] = []
var _weapon_energy: Dictionary = {}
var _full_charge_announced := false


func _ready() -> void:
	if weapon_inventory != null:
		weapon_inventory.current_weapon_changed.connect(_on_weapon_inventory_current_weapon_changed)
		weapon_inventory.inventory_changed.connect(_on_weapon_inventory_changed)

	_sync_weapon_energy_table()
	_emit_weapon_snapshot()
	_emit_current_weapon_energy()
	_set_combat_state(CombatState.READY)
	_set_charge_feedback(ChargeFeedback.NONE)


func _physics_process(delta: float) -> void:
	_prune_tracked_projectiles()
	_update_timers(delta)

	if not combat_enabled:
		return

	var current_weapon := get_current_weapon()
	if current_weapon == null:
		return

	if _handle_weapon_switch_input():
		return

	if combat_state == CombatState.READY and current_weapon.supports_charge and Input.is_action_just_pressed("shoot"):
		_start_charge()
		return

	if combat_state == CombatState.READY and not current_weapon.supports_charge and Input.is_action_just_pressed("shoot"):
		_fire_current_weapon(&"uncharged")
		return

	if combat_state == CombatState.CHARGING or combat_state == CombatState.CHARGED:
		_update_charge(current_weapon, delta)
		if Input.is_action_just_released("shoot"):
			_release_charge(current_weapon)


func get_current_weapon() -> WeaponData:
	if weapon_inventory == null:
		return null

	return weapon_inventory.get_current_weapon()


func get_current_weapon_name() -> String:
	var current_weapon := get_current_weapon()
	return current_weapon.display_name if current_weapon != null else "Offline"


func get_current_weapon_id() -> StringName:
	var current_weapon := get_current_weapon()
	return current_weapon.weapon_id if current_weapon != null else &""


func get_current_weapon_energy() -> int:
	var current_weapon := get_current_weapon()
	if current_weapon == null:
		return 0

	return get_weapon_energy(current_weapon.weapon_id)


func get_current_weapon_max_energy() -> int:
	var current_weapon := get_current_weapon()
	return int(current_weapon.max_energy) if current_weapon != null else 0


func get_current_weapon_accent_color() -> Color:
	var current_weapon := get_current_weapon()
	return current_weapon.ui_accent_color if current_weapon != null else Color.WHITE


func get_weapon_energy(weapon_id: StringName) -> int:
	_sync_weapon_energy_table()
	return int(_weapon_energy.get(weapon_id, 0))


func get_combat_state_name() -> String:
	match combat_state:
		CombatState.READY:
			return "READY"
		CombatState.FIRING:
			return "FIRING"
		CombatState.CHARGING:
			return "CHARGING"
		CombatState.CHARGED:
			return "CHARGED"
		CombatState.COOLDOWN:
			return "COOLDOWN"
		CombatState.DISABLED:
			return "DISABLED"
		_:
			return "UNKNOWN"


func get_charge_feedback_name() -> String:
	match charge_feedback:
		ChargeFeedback.SMALL:
			return "charge_small"
		ChargeFeedback.FULL:
			return "charge_full"
		_:
			return "none"


func get_active_projectile_count() -> int:
	_prune_tracked_projectiles()
	return _tracked_projectiles.size()


func fire_equipped_weapon(tier: StringName = &"uncharged") -> bool:
	return _fire_current_weapon(tier)


func restore_weapon_energy(weapon_id: StringName, amount: int) -> int:
	if amount <= 0:
		return 0

	var weapon := weapon_inventory.get_current_weapon() if weapon_inventory != null and weapon_inventory.has_weapon_unlocked(weapon_id) and get_current_weapon_id() == weapon_id else null
	if weapon == null and weapon_inventory != null:
		for candidate in weapon_inventory.weapon_order:
			if candidate != null and candidate.weapon_id == weapon_id:
				weapon = candidate
				break

	if weapon == null or int(weapon.max_energy) <= 0:
		return 0

	_sync_weapon_energy_table()
	var previous_energy := get_weapon_energy(weapon_id)
	var restored_energy := mini(previous_energy + amount, int(weapon.max_energy))
	_weapon_energy[weapon_id] = restored_energy
	if get_current_weapon_id() == weapon_id:
		_emit_current_weapon_energy()

	return restored_energy - previous_energy


func set_combat_enabled(is_enabled: bool, _reason: StringName = &"") -> void:
	if combat_enabled == is_enabled and (is_enabled or combat_state == CombatState.DISABLED):
		return

	combat_enabled = is_enabled
	if not combat_enabled:
		_cancel_charge()
		_cooldown_remaining = 0.0
		_fire_state_remaining = 0.0
		_set_combat_state(CombatState.DISABLED)
	else:
		_set_charge_feedback(ChargeFeedback.NONE)
		_set_combat_state(CombatState.READY)

	combat_enabled_changed.emit(combat_enabled)


func reset_combat() -> void:
	combat_enabled = true
	_charge_elapsed = 0.0
	_cooldown_remaining = 0.0
	_fire_state_remaining = 0.0
	_tracked_projectiles.clear()
	_full_charge_announced = false
	_refill_weapon_energy()
	_set_charge_feedback(ChargeFeedback.NONE)
	_set_combat_state(CombatState.READY)
	_emit_weapon_snapshot()
	_emit_current_weapon_energy()
	combat_enabled_changed.emit(true)


func _update_timers(delta: float) -> void:
	if _fire_state_remaining > 0.0:
		_fire_state_remaining = maxf(_fire_state_remaining - delta, 0.0)
		if _fire_state_remaining == 0.0 and combat_state == CombatState.FIRING:
			if _cooldown_remaining > 0.0:
				_set_combat_state(CombatState.COOLDOWN)
			else:
				_set_combat_state(CombatState.READY)

	if _cooldown_remaining > 0.0:
		_cooldown_remaining = maxf(_cooldown_remaining - delta, 0.0)
		if _cooldown_remaining == 0.0 and combat_enabled and combat_state == CombatState.COOLDOWN:
			_set_combat_state(CombatState.READY)


func _handle_weapon_switch_input() -> bool:
	if weapon_inventory == null:
		return false

	if combat_state == CombatState.CHARGING or combat_state == CombatState.CHARGED:
		return false

	if Input.is_action_just_pressed("weapon_next"):
		return weapon_inventory.cycle_next()

	if Input.is_action_just_pressed("weapon_prev"):
		return weapon_inventory.cycle_previous()

	return false


func _start_charge() -> void:
	_charge_elapsed = 0.0
	_full_charge_announced = false
	_set_charge_feedback(ChargeFeedback.NONE)
	_set_combat_state(CombatState.CHARGING)
	_play_audio_event(&"player_charge_start")


func _update_charge(current_weapon: WeaponData, delta: float) -> void:
	_charge_elapsed += delta

	if charge_feedback == ChargeFeedback.NONE and _charge_elapsed >= current_weapon.partial_charge_time:
		_set_charge_feedback(ChargeFeedback.SMALL)

	if _charge_elapsed >= current_weapon.full_charge_time:
		_set_charge_feedback(ChargeFeedback.FULL)
		if combat_state != CombatState.CHARGED:
			_set_combat_state(CombatState.CHARGED)
		if not _full_charge_announced:
			_full_charge_announced = true
			_play_audio_event(&"player_charge_full")


func _release_charge(current_weapon: WeaponData) -> void:
	var tier := &"uncharged"
	if _charge_elapsed >= current_weapon.full_charge_time:
		tier = &"full"
	elif _charge_elapsed >= current_weapon.partial_charge_time:
		tier = &"partial"

	_charge_elapsed = 0.0
	_full_charge_announced = false
	_set_charge_feedback(ChargeFeedback.NONE)
	_fire_current_weapon(tier)


func _fire_current_weapon(tier: StringName) -> bool:
	var current_weapon := get_current_weapon()
	if current_weapon == null:
		_set_combat_state(CombatState.READY)
		return false

	if shot_origin == null:
		push_error("PlayerCombat is missing ShotOrigin.")
		_set_combat_state(CombatState.READY)
		return false

	if _cooldown_remaining > 0.0:
		return false

	_prune_tracked_projectiles()
	if _tracked_projectiles.size() >= current_weapon.active_projectile_limit:
		_set_combat_state(CombatState.READY)
		return false

	if not _has_energy_for_shot(current_weapon):
		_set_combat_state(CombatState.READY)
		return false

	var projectile_scene := current_weapon.projectile_scene
	if projectile_scene == null:
		push_error("PlayerCombat weapon '%s' is missing a projectile scene." % current_weapon.weapon_id)
		_set_combat_state(CombatState.READY)
		return false

	var projectile := projectile_scene.instantiate()
	var projectile_parent := _resolve_projectile_parent()
	var spawn_position := _get_shot_spawn_position()
	projectile_parent.add_child(projectile)
	projectile.global_position = spawn_position

	var projectile_setup := _build_projectile_setup(current_weapon, tier)
	if projectile.has_method("configure"):
		projectile.configure(projectile_setup)

	_consume_weapon_energy(current_weapon)
	projectile.tree_exited.connect(_on_projectile_tree_exited.bind(projectile), CONNECT_ONE_SHOT)
	_tracked_projectiles.append(projectile)
	projectile_spawned.emit(projectile, spawn_position, tier)
	shot_fired.emit(current_weapon.weapon_id, tier)

	if tier == &"partial" or tier == &"full":
		_play_audio_event(&"player_charge_release")
	else:
		_play_audio_event(&"player_buster_shot")

	_fire_state_remaining = FIRE_STATE_DURATION
	_cooldown_remaining = current_weapon.shot_cooldown
	_set_combat_state(CombatState.FIRING)
	return true


func _get_shot_spawn_position() -> Vector2:
	var player_node := player as Node2D
	if player_node == null:
		return shot_origin.global_position

	var facing_direction := 1
	if int(player.get("facing_direction")) < 0:
		facing_direction = -1

	var mirrored_offset := shot_origin.position
	mirrored_offset.x *= float(facing_direction)
	return player_node.to_global(mirrored_offset)


func _build_projectile_setup(current_weapon: WeaponData, tier: StringName) -> Dictionary:
	var damage := current_weapon.base_damage
	var visual_scale := current_weapon.uncharged_scale
	var visual_color := current_weapon.uncharged_color
	var knockback := Vector2(110.0, -20.0)

	match tier:
		&"partial":
			damage = current_weapon.partial_charge_damage
			visual_scale = current_weapon.partial_charge_scale
			visual_color = current_weapon.partial_charge_color
			knockback = Vector2(150.0, -35.0)
		&"full":
			damage = current_weapon.full_charge_damage
			visual_scale = current_weapon.full_charge_scale
			visual_color = current_weapon.full_charge_color
			knockback = Vector2(210.0, -48.0)

	return {
		"team": &"player",
		"weapon_id": current_weapon.weapon_id,
		"damage": damage,
		"direction": player.get("facing_direction"),
		"speed": current_weapon.projectile_speed,
		"lifetime": current_weapon.projectile_lifetime,
		"color": visual_color,
		"visual_scale": visual_scale,
		"knockback": knockback,
	}


func _resolve_projectile_parent() -> Node:
	if player != null and player.get_parent() != null:
		return player.get_parent()

	return self


func _sync_weapon_energy_table() -> void:
	if weapon_inventory == null:
		return

	for weapon in weapon_inventory.weapon_order:
		if weapon == null or int(weapon.max_energy) <= 0:
			continue

		if not _weapon_energy.has(weapon.weapon_id):
			_weapon_energy[weapon.weapon_id] = int(weapon.max_energy)


func _refill_weapon_energy() -> void:
	_sync_weapon_energy_table()
	if weapon_inventory == null:
		return

	for weapon in weapon_inventory.weapon_order:
		if weapon == null or int(weapon.max_energy) <= 0:
			continue

		_weapon_energy[weapon.weapon_id] = int(weapon.max_energy)


func _has_energy_for_shot(current_weapon: WeaponData) -> bool:
	if current_weapon == null or int(current_weapon.max_energy) <= 0 or int(current_weapon.energy_cost) <= 0:
		return true

	return get_weapon_energy(current_weapon.weapon_id) >= int(current_weapon.energy_cost)


func _consume_weapon_energy(current_weapon: WeaponData) -> void:
	if current_weapon == null or int(current_weapon.max_energy) <= 0 or int(current_weapon.energy_cost) <= 0:
		return

	_weapon_energy[current_weapon.weapon_id] = maxi(get_weapon_energy(current_weapon.weapon_id) - int(current_weapon.energy_cost), 0)
	_emit_current_weapon_energy()


func _cancel_charge() -> void:
	_charge_elapsed = 0.0
	_full_charge_announced = false
	_set_charge_feedback(ChargeFeedback.NONE)


func _prune_tracked_projectiles() -> void:
	var active_projectiles: Array[Node] = []
	for projectile in _tracked_projectiles:
		if is_instance_valid(projectile):
			active_projectiles.append(projectile)

	_tracked_projectiles = active_projectiles


func _emit_weapon_snapshot() -> void:
	var current_weapon := get_current_weapon()
	if current_weapon == null:
		weapon_changed.emit(&"", "Offline")
		return

	weapon_changed.emit(current_weapon.weapon_id, current_weapon.display_name)


func _emit_current_weapon_energy() -> void:
	var current_weapon := get_current_weapon()
	if current_weapon == null:
		weapon_energy_changed.emit(&"", 0, 0)
		return

	weapon_energy_changed.emit(current_weapon.weapon_id, get_weapon_energy(current_weapon.weapon_id), int(current_weapon.max_energy))


func _set_combat_state(new_state: int) -> void:
	if combat_state == new_state:
		return

	var previous_state := combat_state
	combat_state = new_state
	combat_state_changed.emit(previous_state, combat_state)


func _set_charge_feedback(new_feedback: int) -> void:
	if charge_feedback == new_feedback:
		return

	var previous_feedback := charge_feedback
	charge_feedback = new_feedback
	charge_feedback_changed.emit(previous_feedback, charge_feedback)


func _on_weapon_inventory_current_weapon_changed(weapon_id: StringName, display_name: String) -> void:
	weapon_changed.emit(weapon_id, display_name)
	_emit_current_weapon_energy()


func _on_weapon_inventory_changed() -> void:
	_sync_weapon_energy_table()
	_emit_current_weapon_energy()


func _on_projectile_tree_exited(projectile: Node) -> void:
	_tracked_projectiles.erase(projectile)


func _play_audio_event(event_id: StringName) -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null:
		audio_manager.play_sfx(event_id)

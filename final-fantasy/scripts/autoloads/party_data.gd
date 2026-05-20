class_name PartyData
extends Node

enum Job { WARRIOR, MONK, WHITE_MAGE, BLACK_MAGE }

const JOB_NAMES: Dictionary[Job, StringName] = {
	Job.WARRIOR:    &"Warrior",
	Job.MONK:       &"Monk",
	Job.WHITE_MAGE: &"White Mage",
	Job.BLACK_MAGE: &"Black Mage",
}

# Hit% gained per level by job
const HIT_GROWTH: Dictionary[Job, int] = {
	Job.WARRIOR: 3,
	Job.MONK: 3,
	Job.WHITE_MAGE: 1,
	Job.BLACK_MAGE: 1,
}

# Stat tables: stats at each level (index 0 = level 1, index 1 = level 2, etc.)
# Format: [max_hp, strength, agility, vitality, intelligence, luck]
const GROWTH: Dictionary[Job, Array] = {
	Job.WARRIOR: [
		[35, 10, 8, 15, 1, 8],   # Lv1
		[38, 11, 8, 16, 1, 8],   # Lv2
		[42, 12, 9, 17, 1, 9],   # Lv3
		[46, 13, 9, 18, 1, 9],   # Lv4
		[50, 14, 10, 19, 1, 10],  # Lv5
		[55, 15, 10, 20, 2, 10],  # Lv6
		[60, 16, 11, 21, 2, 11],  # Lv7
		[65, 17, 11, 22, 2, 11],  # Lv8
		[71, 18, 12, 23, 2, 12],  # Lv9
		[77, 19, 12, 24, 2, 12],  # Lv10
		[83, 20, 13, 25, 3, 13],  # Lv11
		[90, 21, 14, 26, 3, 13],  # Lv12
		[97, 22, 14, 27, 3, 14],  # Lv13
		[104, 23, 15, 28, 3, 14], # Lv14
		[112, 24, 15, 29, 3, 15], # Lv15
		[120, 25, 16, 30, 4, 15], # Lv16
		[128, 26, 17, 31, 4, 16], # Lv17
		[137, 27, 17, 32, 4, 16], # Lv18
		[146, 28, 18, 33, 4, 17], # Lv19
		[155, 29, 18, 34, 4, 17], # Lv20
	],
	Job.MONK: [
		[33, 12, 5, 10, 1, 5],
		[37, 13, 5, 11, 1, 5],
		[41, 14, 6, 11, 1, 6],
		[46, 14, 6, 12, 1, 6],
		[51, 15, 7, 12, 1, 7],
		[56, 16, 7, 13, 2, 7],
		[62, 17, 8, 13, 2, 7],
		[68, 17, 8, 14, 2, 8],
		[74, 18, 9, 14, 2, 8],
		[81, 19, 9, 15, 2, 9],
		[88, 20, 10, 16, 3, 9],
		[95, 20, 10, 16, 3, 9],
		[103, 21, 11, 17, 3, 10],
		[111, 22, 11, 17, 3, 10],
		[119, 23, 12, 18, 3, 11],
		[128, 23, 12, 19, 4, 11],
		[137, 24, 13, 19, 4, 11],
		[146, 25, 13, 20, 4, 12],
		[156, 26, 14, 20, 4, 12],
		[166, 26, 14, 21, 4, 13],
	],
	Job.WHITE_MAGE: [
		[33, 5, 5, 8, 15, 5],
		[35, 5, 5, 8, 16, 5],
		[37, 6, 6, 9, 17, 6],
		[39, 6, 6, 9, 18, 6],
		[42, 7, 7, 10, 19, 7],
		[44, 7, 7, 10, 20, 7],
		[47, 7, 7, 11, 21, 7],
		[50, 8, 8, 11, 22, 8],
		[53, 8, 8, 12, 23, 8],
		[56, 9, 9, 12, 24, 9],
		[59, 9, 9, 13, 25, 9],
		[63, 9, 9, 13, 26, 9],
		[67, 10, 10, 14, 27, 10],
		[71, 10, 10, 14, 28, 10],
		[75, 11, 11, 15, 29, 11],
		[79, 11, 11, 15, 30, 11],
		[83, 11, 11, 16, 31, 11],
		[88, 12, 12, 16, 32, 12],
		[93, 12, 12, 17, 33, 12],
		[98, 13, 13, 17, 34, 13],
	],
	Job.BLACK_MAGE: [
		[25, 3, 5, 2, 20, 10],
		[27, 3, 5, 2, 21, 10],
		[29, 4, 6, 3, 22, 11],
		[31, 4, 6, 3, 23, 11],
		[33, 4, 6, 3, 24, 12],
		[35, 5, 7, 4, 25, 12],
		[37, 5, 7, 4, 26, 13],
		[40, 5, 7, 4, 27, 13],
		[43, 6, 8, 5, 28, 14],
		[46, 6, 8, 5, 29, 14],
		[49, 6, 9, 5, 30, 15],
		[52, 7, 9, 6, 31, 15],
		[55, 7, 9, 6, 32, 15],
		[58, 7, 10, 6, 33, 16],
		[62, 8, 10, 7, 34, 16],
		[66, 8, 11, 7, 35, 17],
		[70, 8, 11, 7, 36, 17],
		[74, 9, 11, 8, 37, 18],
		[78, 9, 12, 8, 38, 18],
		[82, 9, 12, 8, 39, 19],
	],
}

# EXP required to reach each level (index 0 = level 2, index 1 = level 3, etc.)
const EXP_TABLE: Array[int] = [
	40,      # Lv2
	105,     # Lv3
	220,     # Lv4
	420,     # Lv5
	740,     # Lv6
	1200,    # Lv7
	1840,    # Lv8
	2680,    # Lv9
	3800,    # Lv10
	5200,    # Lv11
	6900,    # Lv12
	8950,    # Lv13
	11400,   # Lv14
	14300,   # Lv15
	17700,   # Lv16
	21700,   # Lv17
	26400,   # Lv18
	31900,   # Lv19
	38400,   # Lv20
]


class CharacterData:
	var char_name: String
	var job: Job
	var level: int
	var max_hp: int
	var current_hp: int
	var strength: int
	var agility: int
	var vitality: int
	var intelligence: int
	var luck: int
	var current_exp: int = 0
	var base_hit_percent: int = 0

	var weapon: EquipmentData
	var shield: EquipmentData
	var body_armor: EquipmentData
	var head_armor: EquipmentData
	var arm_armor: EquipmentData

	func get_attack_power() -> int:
		if weapon == null and job == Job.MONK:
			return level * 2
		return floori(float(strength) / 2.0) + (weapon.attack_power if weapon else 0)

	func get_absorb() -> int:
		if job == Job.MONK and body_armor == null and shield == null and head_armor == null and arm_armor == null:
			return level
		var total := 0
		for piece: EquipmentData in [shield, body_armor, head_armor, arm_armor]:
			if piece:
				total += piece.absorb
		return total

	func get_evade() -> int:
		var total := 48 + agility
		for piece: EquipmentData in [shield, body_armor, head_armor, arm_armor]:
			if piece:
				total -= piece.evade_penalty
		return total

	func get_hit_percent() -> int:
		if weapon == null and job == Job.MONK:
			return 80 + base_hit_percent
		return (weapon.hit_percent if weapon else 0) + base_hit_percent

	func get_max_hits() -> int:
		return floori(float(get_hit_percent()) / 32.0) + 1

	func get_crit_rate() -> int:
		if weapon:
			return weapon.weapon_index
		if job == Job.MONK:
			return level * 2
		return 0

	func get_exp_to_next() -> int:
		if level >= EXP_TABLE.size() + 1:
			return 0
		return EXP_TABLE[level - 1] - current_exp

	func is_dead() -> bool:
		return current_hp <= 0

	func add_exp(amount: int) -> Array[Dictionary]:
		var level_ups: Array[Dictionary] = []
		current_exp += amount
		while level < EXP_TABLE.size() + 1 and current_exp >= EXP_TABLE[level - 1]:
			level_ups.append(_level_up())
		return level_ups

	func _level_up() -> Dictionary:
		var old_hp := max_hp
		var old_str := strength
		var old_agi := agility
		var old_vit := vitality
		var old_int := intelligence
		var old_lck := luck

		level += 1
		base_hit_percent += HIT_GROWTH[job]
		_apply_level_stats()
		current_hp = max_hp

		return {
			"hp": max_hp - old_hp,
			"str": strength - old_str,
			"agi": agility - old_agi,
			"vit": vitality - old_vit,
			"int": intelligence - old_int,
			"lck": luck - old_lck,
		}

	func _apply_level_stats() -> void:
		var table: Array = GROWTH[job]
		var idx := clampi(level - 1, 0, table.size() - 1)
		var row: Array = table[idx]
		max_hp = row[0]
		strength = row[1]
		agility = row[2]
		vitality = row[3]
		intelligence = row[4]
		luck = row[5]


const POTION := preload("res://data/items/potion.tres")

const RAPIER := preload("res://data/equipment/rapier.tres")
const NUNCHAKU := preload("res://data/equipment/nunchaku.tres")
const HAMMER := preload("res://data/equipment/hammer.tres")
const KNIFE := preload("res://data/equipment/knife.tres")
const LEATHER_SHIELD := preload("res://data/equipment/leather_shield.tres")
const LEATHER_ARMOR := preload("res://data/equipment/leather_armor.tres")
const LEATHER_CAP := preload("res://data/equipment/leather_cap.tres")
const LEATHER_GLOVES := preload("res://data/equipment/leather_gloves.tres")
const CLOTHES := preload("res://data/equipment/clothes.tres")

var party: Array[CharacterData] = []
var inventory: Dictionary = {}
var gil: int = 0
var play_time: float = 0.0

func _ready() -> void:
	party = [
		_create(Job.WARRIOR,    35, 10, 8, 15,  1,  8),
		_create(Job.MONK,       33, 12, 5, 10,  1,  5),
		_create(Job.WHITE_MAGE, 33,  5, 5,  8, 15,  5),
		_create(Job.BLACK_MAGE, 25,  3, 5,  2, 20, 10),
	]
	_equip_starter_gear()
	add_item(POTION, 3)

func _process(delta: float) -> void:
	if GameState.is_state(GameState.State.FIELD):
		play_time += delta

func add_item(item: ItemData, qty: int = 1) -> void:
	if item in inventory:
		inventory[item] += qty
	else:
		inventory[item] = qty

func remove_item(item: ItemData, qty: int = 1) -> void:
	if item not in inventory:
		return
	inventory[item] -= qty
	if inventory[item] <= 0:
		var _erased: bool = inventory.erase(item)

func use_item(item: ItemData, target: CharacterData) -> bool:
	if item not in inventory:
		return false
	if item.effect_type == ItemData.EffectType.HEAL_HP:
		target.current_hp = mini(target.current_hp + item.potency, target.max_hp)
	remove_item(item)
	return true

func get_play_time_string() -> String:
	var total_seconds: int = int(play_time)
	var hours: int = floori(float(total_seconds) / 3600.0)
	var minutes: int = floori(float(total_seconds % 3600) / 60.0)
	return "%02d:%02d" % [hours, minutes]

func _create(job: Job, hp: int, str_: int, agi: int, vit: int, int_: int, lck: int) -> CharacterData:
	var c := CharacterData.new()
	c.char_name = JOB_NAMES[job]
	c.job = job
	c.level = 1
	c.max_hp = hp
	c.current_hp = hp
	c.strength = str_
	c.agility = agi
	c.vitality = vit
	c.intelligence = int_
	c.luck = lck
	return c

func _equip_starter_gear() -> void:
	var warrior := party[0]
	warrior.weapon = RAPIER
	warrior.shield = LEATHER_SHIELD
	warrior.body_armor = LEATHER_ARMOR
	warrior.head_armor = LEATHER_CAP
	warrior.arm_armor = LEATHER_GLOVES

	var monk := party[1]
	monk.body_armor = CLOTHES
	monk.arm_armor = LEATHER_GLOVES

	var white_mage := party[2]
	white_mage.weapon = HAMMER
	white_mage.body_armor = CLOTHES
	white_mage.arm_armor = LEATHER_GLOVES

	var black_mage := party[3]
	black_mage.weapon = KNIFE
	black_mage.body_armor = CLOTHES
	black_mage.arm_armor = LEATHER_GLOVES

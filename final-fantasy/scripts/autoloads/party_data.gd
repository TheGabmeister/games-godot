extends Node

enum Job { WARRIOR, MONK, WHITE_MAGE, BLACK_MAGE }

const JOB_NAMES: Dictionary[Job, StringName] = {
	Job.WARRIOR:    &"Warrior",
	Job.MONK:       &"Monk",
	Job.WHITE_MAGE: &"White Mage",
	Job.BLACK_MAGE: &"Black Mage",
}

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

const POTION := preload("res://data/items/potion.tres")

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

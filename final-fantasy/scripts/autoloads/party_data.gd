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

var party: Array[CharacterData] = []

func _ready() -> void:
	party = [
		_create(Job.WARRIOR,    35, 10, 8, 15,  1,  8),
		_create(Job.MONK,       33, 12, 5, 10,  1,  5),
		_create(Job.WHITE_MAGE, 33,  5, 5,  8, 15,  5),
		_create(Job.BLACK_MAGE, 25,  3, 5,  2, 20, 10),
	]

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

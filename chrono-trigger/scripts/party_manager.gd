extends Node

var members: Array = []

func _ready() -> void:
	add_to_group(Groups.PARTY_MANAGER)

func initialize(party_nodes: Array) -> void:
	members.clear()
	for node in party_nodes:
		var char_data: CharacterData = node.data
		members.append({
			"data": char_data,
			"current_hp": char_data.max_hp,
			"is_ko": false,
			"node": node,
		})

func get_living_members() -> Array:
	var result: Array = []
	for m in members:
		if not m["is_ko"]:
			result.append(m)
	return result

func update_from_battle(battle_state: Array) -> void:
	for i in mini(battle_state.size(), members.size()):
		members[i]["current_hp"] = battle_state[i]["current_hp"]
		members[i]["is_ko"] = battle_state[i]["current_hp"] <= 0

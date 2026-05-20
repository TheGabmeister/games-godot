class_name BattleTypes

enum CommandType { ATTACK, ITEM, RUN }

class BattleCommand:
	var type: CommandType
	var actor_index: int
	var target_index: int = -1
	var item: ItemData
	var is_enemy_command: bool = false

class Battler:
	var display_name: String
	var max_hp: int
	var current_hp: int
	var attack_power: int
	var accuracy: int
	var defense: int
	var agility: int
	var evade: int
	var crit_rate: int
	var max_hits: int
	var is_party: bool
	var party_index: int = -1
	var character_data: PartyData.CharacterData
	var enemy_data: EnemyData
	var sprite: Sprite2D
	var home_position: Vector2

	func is_dead() -> bool:
		return current_hp <= 0

	func take_damage(amount: int) -> void:
		current_hp = maxi(0, current_hp - amount)
		if character_data:
			character_data.current_hp = current_hp

	func heal(amount: int) -> void:
		current_hp = mini(current_hp + amount, max_hp)
		if character_data:
			character_data.current_hp = current_hp

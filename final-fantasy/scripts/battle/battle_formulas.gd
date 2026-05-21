class_name BattleFormulas

const FORMATION_WEIGHTS: Array[int] = [8, 4, 2, 2]

static func physical_damage(attack_power: int, absorb: int, is_crit: bool) -> int:
	var raw := randi_range(attack_power, attack_power * 2)
	if not is_crit:
		raw -= absorb
	return maxi(1, raw)

static func hit_check(attacker_hit: int, defender_evade: int) -> bool:
	var chance := 168 + attacker_hit - defender_evade
	return randi_range(1, 200) <= chance

static func crit_check(crit_rate: int) -> bool:
	if crit_rate <= 0:
		return false
	return randi_range(1, 200) <= crit_rate

static func run_chance(party_avg_luck: float, enemy_avg_agility: float) -> bool:
	var chance := party_avg_luck * 2.0 - enemy_avg_agility + 80.0
	return randi_range(1, 100) <= int(chance)

static func pick_party_target(party_indices: Array[int]) -> int:
	var total := 0
	for idx: int in party_indices:
		total += FORMATION_WEIGHTS[idx]
	var roll := randi_range(1, total)
	var accum := 0
	for idx: int in party_indices:
		accum += FORMATION_WEIGHTS[idx]
		if roll <= accum:
			return idx
	return party_indices.back()

static func distribute_exp(total_exp: int, alive_count: int) -> int:
	if alive_count <= 0:
		return 0
	return floori(float(total_exp) / float(alive_count))

static func magic_damage(spell_power: int) -> int:
	return randi_range(spell_power, spell_power * 2)

static func spell_hit_check(spell_accuracy: int, target_magic_defense: int) -> bool:
	var chance := spell_accuracy - target_magic_defense
	return randf() * 100.0 < chance

static func spell_hit_with_element(spell_accuracy: int, target_magic_defense: int, element: SpellData.Element, weaknesses: Array[SpellData.Element]) -> bool:
	var chance := spell_accuracy - target_magic_defense
	if element != SpellData.Element.NONE and element in weaknesses:
		chance += 20
	return randf() * 100.0 < chance

static func apply_elemental_modifiers(damage: int, element: SpellData.Element, weaknesses: Array[SpellData.Element], target_resistances: Array[SpellData.Element]) -> Dictionary:
	var weak := element != SpellData.Element.NONE and element in weaknesses
	var resist := element != SpellData.Element.NONE and element in target_resistances
	var modified := damage
	if weak:
		modified = floori(float(modified) * 1.5)
	if resist:
		modified = floori(float(modified) * 0.5)
	return { "damage": modified, "weak": weak, "resist": resist }

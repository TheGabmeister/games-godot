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

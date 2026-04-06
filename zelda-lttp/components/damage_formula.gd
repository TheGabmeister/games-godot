class_name DamageFormula

## Full damage pipeline result.
## Returns a dictionary with:
##   "blocked": bool — shield blocked it entirely
##   "immune": bool — target is immune to this damage type
##   "final_damage": int — damage after all reductions (0 if blocked/immune)
##   "raw_damage": int — damage before armor

## Step 1: Shield check (projectile-only, must be called separately by shield logic)
## This function handles Steps 2-4.

static func calculate_damage(
	raw_damage: int,
	damage_type: int,
	armor_tier: int,
	damage_immunities: Array = []
) -> Dictionary:

	# Step 2 — Immunity check
	if damage_type in damage_immunities:
		return {"blocked": false, "immune": true, "final_damage": 0, "raw_damage": raw_damage}

	# Step 3 — Armor reduction (player only)
	var final_damage: int = raw_damage

	if damage_type in DamageType.ENVIRONMENTAL_TYPES:
		# Environmental damage bypasses armor entirely
		final_damage = raw_damage
	else:
		# Combat damage — apply armor reduction
		match armor_tier:
			0, 1:
				# No reduction (tier 0 = no armor, tier 1 = Green Mail baseline)
				final_damage = raw_damage
			2:
				# Blue Mail: halve, round up
				final_damage = ceili(float(raw_damage) / 2.0)
			3:
				# Red Mail: quarter, round up
				final_damage = ceili(float(raw_damage) / 4.0)

		# Minimum 1 damage after armor (armor never fully negates)
		final_damage = maxi(final_damage, 1)

	# Step 4 — Return final damage (apply_damage called by the caller)
	return {"blocked": false, "immune": false, "final_damage": final_damage, "raw_damage": raw_damage}

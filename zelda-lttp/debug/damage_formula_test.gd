extends Node2D

var _results: Array[String] = []


func _ready() -> void:
	_test_no_armor()
	_test_green_mail()
	_test_blue_mail()
	_test_red_mail()
	_test_environmental_bypass()
	_test_immunity()
	_test_minimum_damage()
	_test_enemy_data_load()
	_test_enemy_data_immunities()

	for r in _results:
		print(r)
	queue_redraw()


func _test_no_armor() -> void:
	var r := DamageFormula.calculate_damage(4, DamageType.Type.CONTACT, 0)
	_assert_eq(r.final_damage, 4, "No armor (tier 0): 4 CONTACT -> 4")

	r = DamageFormula.calculate_damage(8, DamageType.Type.SWORD, 0)
	_assert_eq(r.final_damage, 8, "No armor (tier 0): 8 SWORD -> 8")


func _test_green_mail() -> void:
	var r := DamageFormula.calculate_damage(4, DamageType.Type.CONTACT, 1)
	_assert_eq(r.final_damage, 4, "Green Mail (tier 1): 4 CONTACT -> 4 (no reduction)")


func _test_blue_mail() -> void:
	# Halve, round up
	var r := DamageFormula.calculate_damage(4, DamageType.Type.CONTACT, 2)
	_assert_eq(r.final_damage, 2, "Blue Mail: 4 CONTACT -> 2")

	r = DamageFormula.calculate_damage(3, DamageType.Type.ARROW, 2)
	_assert_eq(r.final_damage, 2, "Blue Mail: 3 ARROW -> 2 (ceil)")

	r = DamageFormula.calculate_damage(8, DamageType.Type.BOMB, 2)
	_assert_eq(r.final_damage, 4, "Blue Mail: 8 BOMB -> 4")

	r = DamageFormula.calculate_damage(12, DamageType.Type.FIRE, 2)
	_assert_eq(r.final_damage, 6, "Blue Mail: 12 FIRE -> 6")


func _test_red_mail() -> void:
	# Quarter, round up
	var r := DamageFormula.calculate_damage(8, DamageType.Type.CONTACT, 3)
	_assert_eq(r.final_damage, 2, "Red Mail: 8 CONTACT -> 2")

	r = DamageFormula.calculate_damage(12, DamageType.Type.ICE, 3)
	_assert_eq(r.final_damage, 3, "Red Mail: 12 ICE -> 3")

	r = DamageFormula.calculate_damage(16, DamageType.Type.MAGIC, 3)
	_assert_eq(r.final_damage, 4, "Red Mail: 16 MAGIC -> 4")

	r = DamageFormula.calculate_damage(5, DamageType.Type.SWORD, 3)
	_assert_eq(r.final_damage, 2, "Red Mail: 5 SWORD -> 2 (ceil)")


func _test_environmental_bypass() -> void:
	# PIT, WATER, SPIKE bypass armor entirely
	var r := DamageFormula.calculate_damage(2, DamageType.Type.PIT, 3)
	_assert_eq(r.final_damage, 2, "Red Mail: 2 PIT -> 2 (bypasses armor)")

	r = DamageFormula.calculate_damage(2, DamageType.Type.SPIKE, 3)
	_assert_eq(r.final_damage, 2, "Red Mail: 2 SPIKE -> 2 (bypasses armor)")

	r = DamageFormula.calculate_damage(2, DamageType.Type.WATER, 2)
	_assert_eq(r.final_damage, 2, "Blue Mail: 2 WATER -> 2 (bypasses armor)")


func _test_immunity() -> void:
	var immunities: Array = [DamageType.Type.FIRE, DamageType.Type.ICE]

	var r := DamageFormula.calculate_damage(8, DamageType.Type.FIRE, 0, immunities)
	_assert_eq(r.final_damage, 0, "Immune to FIRE: 0 damage")
	_assert_eq(r.immune, true, "Immune flag set")

	r = DamageFormula.calculate_damage(4, DamageType.Type.SWORD, 0, immunities)
	_assert_eq(r.final_damage, 4, "Not immune to SWORD: 4 damage")
	_assert_eq(r.immune, false, "Immune flag not set")


func _test_minimum_damage() -> void:
	# Armor can't reduce combat damage below 1
	var r := DamageFormula.calculate_damage(1, DamageType.Type.CONTACT, 3)
	_assert_eq(r.final_damage, 1, "Red Mail: 1 CONTACT -> 1 (minimum)")

	r = DamageFormula.calculate_damage(2, DamageType.Type.ARROW, 3)
	_assert_eq(r.final_damage, 1, "Red Mail: 2 ARROW -> 1 (ceil(0.5) = 1)")


func _test_enemy_data_load() -> void:
	var paths := [
		"res://resources/enemies/soldier.tres",
		"res://resources/enemies/octorok.tres",
		"res://resources/enemies/keese.tres",
		"res://resources/enemies/stalfos.tres",
		"res://resources/enemies/buzz_blob.tres",
	]
	for p in paths:
		var res := load(p)
		if res is EnemyData:
			var ed: EnemyData = res
			_assert_eq(ed.id != &"", true, "EnemyData '%s' has id" % p.get_file())
			_assert_eq(ed.max_health > 0, true, "EnemyData '%s' has health" % p.get_file())
		else:
			_assert_eq(false, true, "EnemyData '%s' failed to load" % p.get_file())


func _test_enemy_data_immunities() -> void:
	var buzz: EnemyData = load("res://resources/enemies/buzz_blob.tres")
	_assert_eq(buzz.damage_immunities.size() > 0, true, "Buzz Blob has immunities")
	_assert_eq(DamageType.Type.SWORD in buzz.damage_immunities, true, "Buzz Blob immune to SWORD")

	# DamageFormula rejects SWORD hits using Buzz Blob immunities
	var r := DamageFormula.calculate_damage(4, DamageType.Type.SWORD, 0, buzz.damage_immunities)
	_assert_eq(r.immune, true, "Buzz Blob: SWORD hit rejected")
	_assert_eq(r.final_damage, 0, "Buzz Blob: SWORD does 0 damage")

	# Non-immune type still deals damage
	r = DamageFormula.calculate_damage(4, DamageType.Type.ARROW, 0, buzz.damage_immunities)
	_assert_eq(r.immune, false, "Buzz Blob: ARROW not immune")
	_assert_eq(r.final_damage, 4, "Buzz Blob: ARROW does 4 damage")

	# Soldier has no immunities — SWORD works normally
	var soldier: EnemyData = load("res://resources/enemies/soldier.tres")
	r = DamageFormula.calculate_damage(4, DamageType.Type.SWORD, 0, soldier.damage_immunities)
	_assert_eq(r.immune, false, "Soldier: SWORD not immune")
	_assert_eq(r.final_damage, 4, "Soldier: SWORD does 4 damage")


func _assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual == expected:
		_results.append("[PASS] %s" % label)
	else:
		_results.append("[FAIL] %s (got %s, expected %s)" % [label, actual, expected])


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(256, 224)), Color(0.12, 0.12, 0.15))
	draw_string(ThemeDB.fallback_font, Vector2(8, 14), "Damage Formula Tests", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)

	for i in _results.size():
		var r: String = _results[i]
		var color := Color.GREEN if r.begins_with("[PASS]") else Color.RED
		draw_string(ThemeDB.fallback_font, Vector2(4, 28 + i * 10), r, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, color)

extends Node2D

var _results: Array[String] = []


func _ready() -> void:
	_test_empty_table()
	_test_single_entry()
	_test_weighted_distribution()
	_test_nothing_weight()
	_test_quantity_range()
	_test_weight_mismatch_fix()

	for r in _results:
		print(r)
	queue_redraw()


func _test_empty_table() -> void:
	var table := LootTable.new()
	var result: Array[ItemData] = table.roll()
	_assert_eq(result.is_empty(), true, "Empty table returns empty array")


func _test_single_entry() -> void:
	var table := LootTable.new()
	table.item_ids = PackedStringArray(["heart"])
	table.weights = PackedFloat32Array([1.0])
	table.nothing_weight = 0.0

	var all_heart := true
	for i in 100:
		var result: Array[ItemData] = table.roll()
		if result.is_empty() or result[0].id != &"heart":
			all_heart = false
			break
	_assert_eq(all_heart, true, "Single entry (no nothing): always returns that entry")


func _test_weighted_distribution() -> void:
	var table := LootTable.new()
	table.item_ids = PackedStringArray(["heart", "rupee_green"])
	table.weights = PackedFloat32Array([1.0, 3.0])
	table.nothing_weight = 0.0

	var counts := {"heart": 0, "rupee_green": 0}
	var total := 10000
	for i in total:
		var result: Array[ItemData] = table.roll()
		if not result.is_empty():
			counts[String(result[0].id)] += 1

	var heart_pct: float = float(counts["heart"]) / float(total)
	var rupee_pct: float = float(counts["rupee_green"]) / float(total)

	var heart_ok: bool = heart_pct > 0.20 and heart_pct < 0.30
	var rupee_ok: bool = rupee_pct > 0.70 and rupee_pct < 0.80

	_assert_eq(heart_ok, true, "Weighted dist: heart ~25%% (got %.1f%%)" % [heart_pct * 100])
	_assert_eq(rupee_ok, true, "Weighted dist: rupee ~75%% (got %.1f%%)" % [rupee_pct * 100])


func _test_nothing_weight() -> void:
	var table := LootTable.new()
	table.item_ids = PackedStringArray(["heart"])
	table.weights = PackedFloat32Array([1.0])
	table.nothing_weight = 1.0

	var empty_count := 0
	var total := 10000
	for i in total:
		var result: Array[ItemData] = table.roll()
		if result.is_empty():
			empty_count += 1

	var nothing_pct: float = float(empty_count) / float(total)
	var ok: bool = nothing_pct > 0.45 and nothing_pct < 0.55
	_assert_eq(ok, true, "Nothing weight ~50%% (got %.1f%%)" % [nothing_pct * 100])


func _test_quantity_range() -> void:
	var table := LootTable.new()
	table.item_ids = PackedStringArray(["rupee_green"])
	table.weights = PackedFloat32Array([1.0])
	table.quantity_min = PackedInt32Array([2])
	table.quantity_max = PackedInt32Array([4])
	table.nothing_weight = 0.0

	var min_seen := 999
	var max_seen := 0
	for i in 200:
		var result: Array[ItemData] = table.roll()
		var count: int = result.size()
		min_seen = mini(min_seen, count)
		max_seen = maxi(max_seen, count)

	_assert_eq(min_seen >= 2, true, "Quantity min: smallest drop >= 2 (got %d)" % min_seen)
	_assert_eq(max_seen <= 4, true, "Quantity max: largest drop <= 4 (got %d)" % max_seen)
	_assert_eq(max_seen > min_seen, true, "Quantity range: saw variation (min=%d, max=%d)" % [min_seen, max_seen])


func _test_weight_mismatch_fix() -> void:
	# 3 items but only 1 weight — trailing items should use fallback 1.0
	var table := LootTable.new()
	table.item_ids = PackedStringArray(["heart", "rupee_green", "rupee_blue"])
	table.weights = PackedFloat32Array([1.0])
	table.nothing_weight = 0.0

	var counts := {"heart": 0, "rupee_green": 0, "rupee_blue": 0}
	var total := 10000
	for i in total:
		var result: Array[ItemData] = table.roll()
		if not result.is_empty():
			counts[String(result[0].id)] += 1

	# Weights: 1.0, 1.0(fallback), 1.0(fallback) → ~33% each
	var all_reachable: bool = counts["heart"] > 0 and counts["rupee_green"] > 0 and counts["rupee_blue"] > 0
	_assert_eq(all_reachable, true, "Weight mismatch: all 3 items reachable")

	var blue_pct: float = float(counts["rupee_blue"]) / float(total)
	var blue_ok: bool = blue_pct > 0.25 and blue_pct < 0.42
	_assert_eq(blue_ok, true, "Weight mismatch: trailing item ~33%% (got %.1f%%)" % [blue_pct * 100])


func _assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual == expected:
		_results.append("[PASS] %s" % label)
	else:
		_results.append("[FAIL] %s (got %s, expected %s)" % [label, actual, expected])


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(256, 224)), Color(0.12, 0.12, 0.15))
	draw_string(ThemeDB.fallback_font, Vector2(8, 14), "Loot Table Tests", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)

	for i in _results.size():
		var r: String = _results[i]
		var color := Color.GREEN if r.begins_with("[PASS]") else Color.RED
		draw_string(ThemeDB.fallback_font, Vector2(4, 28 + i * 10), r, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, color)

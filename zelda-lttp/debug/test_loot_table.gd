extends Node2D

var _results: Array[String] = []


func _ready() -> void:
	_test_empty_table()
	_test_single_entry()
	_test_weighted_distribution()
	_test_nothing_weight()

	for r in _results:
		print(r)
	queue_redraw()


func _test_empty_table() -> void:
	var table := LootTable.new()
	var result: ItemData = table.roll()
	_assert_eq(result == null, true, "Empty table returns null")


func _test_single_entry() -> void:
	var table := LootTable.new()
	table.item_ids = PackedStringArray(["heart"])
	table.weights = PackedFloat32Array([1.0])
	table.nothing_weight = 0.0

	var all_heart := true
	for i in 100:
		var result: ItemData = table.roll()
		if result == null or result.id != &"heart":
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
		var result: ItemData = table.roll()
		if result:
			counts[String(result.id)] += 1

	var heart_pct: float = float(counts["heart"]) / float(total)
	var rupee_pct: float = float(counts["rupee_green"]) / float(total)

	# Expect ~25% heart, ~75% rupee_green (tolerance ±5%)
	var heart_ok: bool = heart_pct > 0.20 and heart_pct < 0.30
	var rupee_ok: bool = rupee_pct > 0.70 and rupee_pct < 0.80

	_assert_eq(heart_ok, true, "Weighted dist: heart ~25%% (got %.1f%%)" % [heart_pct * 100])
	_assert_eq(rupee_ok, true, "Weighted dist: rupee ~75%% (got %.1f%%)" % [rupee_pct * 100])


func _test_nothing_weight() -> void:
	var table := LootTable.new()
	table.item_ids = PackedStringArray(["heart"])
	table.weights = PackedFloat32Array([1.0])
	table.nothing_weight = 1.0

	var null_count := 0
	var total := 10000
	for i in total:
		var result: ItemData = table.roll()
		if result == null:
			null_count += 1

	var nothing_pct: float = float(null_count) / float(total)
	# Expect ~50% nothing (tolerance ±5%)
	var ok: bool = nothing_pct > 0.45 and nothing_pct < 0.55
	_assert_eq(ok, true, "Nothing weight ~50%% (got %.1f%%)" % [nothing_pct * 100])


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

extends Node

## Phase 3 PlayerState unit tests
## Run: load this scene, check Output for PASS/FAIL

var _pass_count: int = 0
var _fail_count: int = 0
var _total_count: int = 0


func _ready() -> void:
	# Wait a frame for autoloads
	await get_tree().process_frame
	_run_tests()


func _run_tests() -> void:
	print("\n=== PlayerState Unit Tests ===\n")

	# Save original state
	var orig_health: int = PlayerState.current_health
	var orig_max: int = PlayerState.max_health
	var orig_magic: int = PlayerState.current_magic
	var orig_rupees: int = PlayerState.rupees
	var orig_arrows: int = PlayerState.arrows
	var orig_bombs: int = PlayerState.bombs
	var orig_pieces: int = PlayerState.heart_pieces
	var orig_skills: Dictionary = PlayerState.owned_skills.duplicate()
	var orig_upgrades: Dictionary = PlayerState.upgrades.duplicate()
	var orig_equipped: StringName = PlayerState.equipped_skill_id

	# --- SKILL tests ---
	_test_skill_acquisition()
	_test_skill_equip()

	# --- UPGRADE tests ---
	_test_upgrade_acquisition()
	_test_upgrade_monotonicity()

	# --- RESOURCE tests ---
	_test_heart_pieces()
	_test_rupee_cap()
	_test_damage_and_heal()
	_test_consume_skill_cost()
	_test_magic_halver()
	_test_reduce_upgrade()
	_test_small_keys()

	print("\n=== Results: %d/%d passed ===\n" % [_pass_count, _total_count])

	# Restore state
	PlayerState.current_health = orig_health
	PlayerState.max_health = orig_max
	PlayerState.current_magic = orig_magic
	PlayerState.rupees = orig_rupees
	PlayerState.arrows = orig_arrows
	PlayerState.bombs = orig_bombs
	PlayerState.heart_pieces = orig_pieces
	PlayerState.owned_skills = orig_skills
	PlayerState.upgrades = orig_upgrades
	PlayerState.equipped_skill_id = orig_equipped
	PlayerState.skill_effects.clear()


func _test_skill_acquisition() -> void:
	PlayerState.owned_skills.clear()
	PlayerState.skill_effects.clear()
	PlayerState.equipped_skill_id = &""

	var bow: ItemData = ItemRegistry.get_item(&"bow")
	if not bow:
		_assert(false, "SKILL: bow.tres not found in ItemRegistry")
		return

	PlayerState.acquire(bow)
	_assert(PlayerState.has_skill(&"bow"), "SKILL: acquire(bow) -> has_skill('bow') is true")
	_assert(PlayerState.equipped_skill_id == &"bow", "SKILL: auto-equips bow when slot empty")
	_assert(PlayerState.get_equipped_skill() != null, "SKILL: get_equipped_skill() returns bow")


func _test_skill_equip() -> void:
	PlayerState.owned_skills.clear()
	PlayerState.skill_effects.clear()
	PlayerState.equipped_skill_id = &""

	var bow: ItemData = ItemRegistry.get_item(&"bow")
	var boom: ItemData = ItemRegistry.get_item(&"boomerang")
	if not bow or not boom:
		_assert(false, "SKILL equip: items not found")
		return

	PlayerState.acquire(bow)
	PlayerState.acquire(boom)
	_assert(PlayerState.equipped_skill_id == &"bow", "SKILL equip: first acquired stays equipped")

	PlayerState.equip_skill(&"boomerang")
	_assert(PlayerState.equipped_skill_id == &"boomerang", "SKILL equip: equip_skill changes equipped")


func _test_upgrade_acquisition() -> void:
	PlayerState.upgrades.clear()

	var boots: ItemData = ItemRegistry.get_item(&"pegasus_boots")
	if not boots:
		_assert(false, "UPGRADE: pegasus_boots.tres not found")
		return

	PlayerState.acquire(boots)
	_assert(PlayerState.get_upgrade(&"boots") == 1, "UPGRADE: acquire(boots) -> get_upgrade('boots') == 1")
	_assert(PlayerState.has_upgrade(&"boots"), "UPGRADE: has_upgrade('boots') is true")

	# Re-acquiring same tier doesn't change it
	PlayerState.acquire(boots)
	_assert(PlayerState.get_upgrade(&"boots") == 1, "UPGRADE: re-acquire same tier stays at 1")


func _test_upgrade_monotonicity() -> void:
	PlayerState.upgrades.clear()

	var s1: ItemData = ItemRegistry.get_item(&"sword_t1")
	var s3: ItemData = ItemRegistry.get_item(&"sword_t3")
	if not s1 or not s3:
		_assert(false, "UPGRADE monotonicity: sword items not found")
		return

	PlayerState.acquire(s1)
	_assert(PlayerState.get_upgrade(&"sword") == 1, "UPGRADE mono: sword starts at tier 1")

	PlayerState.acquire(s3)
	_assert(PlayerState.get_upgrade(&"sword") == 3, "UPGRADE mono: sword upgrades to tier 3")

	PlayerState.acquire(s1)
	_assert(PlayerState.get_upgrade(&"sword") == 3, "UPGRADE mono: re-acquiring t1 does NOT downgrade from 3")


func _test_heart_pieces() -> void:
	PlayerState.heart_pieces = 0
	PlayerState.max_health = 6
	PlayerState.current_health = 6

	var piece := ItemData.new()
	piece.item_type = ItemData.ItemType.RESOURCE
	piece.resource_key = &"heart_piece"
	piece.resource_amount = 1
	piece.id = &"test_piece"

	for i in range(3):
		PlayerState.acquire(piece)
	_assert(PlayerState.heart_pieces == 3, "RESOURCE: 3 heart pieces = count 3")
	_assert(PlayerState.max_health == 6, "RESOURCE: 3 pieces, max_health still 6")

	PlayerState.acquire(piece)
	_assert(PlayerState.heart_pieces == 0, "RESOURCE: 4th piece resets counter to 0")
	_assert(PlayerState.max_health == 8, "RESOURCE: 4 pieces increases max_health by 2 (6->8)")


func _test_rupee_cap() -> void:
	PlayerState.rupees = 990

	var rupee := ItemData.new()
	rupee.item_type = ItemData.ItemType.RESOURCE
	rupee.resource_key = &"rupees"
	rupee.resource_amount = 20
	rupee.id = &"test_rupee"

	PlayerState.acquire(rupee)
	_assert(PlayerState.rupees == 999, "RESOURCE: rupees cap at 999 (990 + 20 = 999, not 1010)")


func _test_damage_and_heal() -> void:
	PlayerState.current_health = 6
	PlayerState.max_health = 6

	PlayerState.apply_damage(2)
	_assert(PlayerState.current_health == 4, "RESOURCE: apply_damage(2) at 6 -> 4")

	PlayerState.heal(1)
	_assert(PlayerState.current_health == 5, "RESOURCE: heal(1) at 4 -> 5")

	PlayerState.heal(999)
	_assert(PlayerState.current_health == 6, "RESOURCE: heal clamps to max_health")

	PlayerState.apply_damage(999)
	_assert(PlayerState.current_health == 0, "RESOURCE: apply_damage clamps to 0")


func _test_consume_skill_cost() -> void:
	PlayerState.current_magic = 10
	PlayerState.arrows = 5

	var bow: ItemData = ItemRegistry.get_item(&"bow")
	if not bow:
		_assert(false, "consume_skill_cost: bow not found")
		return

	var ok: bool = PlayerState.consume_skill_cost(bow)
	_assert(ok, "consume_skill_cost: bow succeeds with 5 arrows")
	_assert(PlayerState.arrows == 4, "consume_skill_cost: arrows decremented to 4")

	PlayerState.arrows = 0
	ok = PlayerState.consume_skill_cost(bow)
	_assert(not ok, "consume_skill_cost: bow fails with 0 arrows")
	_assert(PlayerState.arrows == 0, "consume_skill_cost: arrows unchanged on failure")

	# Magic cost test
	var lamp: ItemData = ItemRegistry.get_item(&"lamp")
	if lamp:
		PlayerState.current_magic = 3
		ok = PlayerState.consume_skill_cost(lamp)
		_assert(not ok, "consume_skill_cost: lamp fails with 3 magic (needs 4)")
		_assert(PlayerState.current_magic == 3, "consume_skill_cost: magic unchanged on failure")

		PlayerState.current_magic = 10
		ok = PlayerState.consume_skill_cost(lamp)
		_assert(ok, "consume_skill_cost: lamp succeeds with 10 magic")
		_assert(PlayerState.current_magic == 6, "consume_skill_cost: magic decremented 10->6")


func _test_magic_halver() -> void:
	PlayerState.upgrades.clear()
	PlayerState.current_magic = 10

	var lamp: ItemData = ItemRegistry.get_item(&"lamp")
	if not lamp:
		_assert(false, "magic_halver: lamp not found")
		return

	# Without magic halver: lamp costs 4
	PlayerState.consume_skill_cost(lamp)
	_assert(PlayerState.current_magic == 6, "magic_halver: without upgrade, lamp costs 4 (10->6)")

	# With magic halver: lamp costs 2
	PlayerState.current_magic = 10
	PlayerState.upgrades[&"magic_halver"] = 1
	PlayerState.consume_skill_cost(lamp)
	_assert(PlayerState.current_magic == 8, "magic_halver: with upgrade, lamp costs 2 (10->8)")

	# Fire Rod: 8 -> 4
	var fire_rod: ItemData = ItemRegistry.get_item(&"fire_rod")
	if fire_rod:
		PlayerState.current_magic = 10
		PlayerState.consume_skill_cost(fire_rod)
		_assert(PlayerState.current_magic == 6, "magic_halver: fire rod costs 4 instead of 8 (10->6)")


func _test_reduce_upgrade() -> void:
	PlayerState.upgrades[&"shield"] = 3

	PlayerState.reduce_upgrade(&"shield", 1)
	_assert(PlayerState.get_upgrade(&"shield") == 2, "reduce_upgrade: shield 3 - 1 = 2")

	PlayerState.reduce_upgrade(&"shield", 5)
	_assert(PlayerState.get_upgrade(&"shield") == 0, "reduce_upgrade: clamps to 0")


func _test_small_keys() -> void:
	PlayerState.dungeon_small_keys.clear()

	PlayerState.add_small_key(&"dungeon_01", 2)
	_assert(PlayerState.dungeon_small_keys.get(&"dungeon_01", 0) == 2, "small_keys: add 2 to dungeon_01")

	var ok: bool = PlayerState.use_small_key(&"dungeon_01")
	_assert(ok, "small_keys: use_small_key returns true with 2 keys")
	_assert(PlayerState.dungeon_small_keys[&"dungeon_01"] == 1, "small_keys: count decremented to 1")

	ok = PlayerState.use_small_key(&"dungeon_02")
	_assert(not ok, "small_keys: use_small_key returns false for dungeon with 0 keys")


func _assert(condition: bool, description: String) -> void:
	_total_count += 1
	if condition:
		_pass_count += 1
		print("  PASS: %s" % description)
	else:
		_fail_count += 1
		print("  FAIL: %s" % description)

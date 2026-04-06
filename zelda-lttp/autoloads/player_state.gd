extends Node

enum BottleContents {
	EMPTY,
	RED_POTION,
	GREEN_POTION,
	BLUE_POTION,
	FAIRY,
	BEE,
	GOOD_BEE,
	MAGIC_POWDER,
}

# Skills
var equipped_skill_id: StringName = &""
var owned_skills: Dictionary = {}  # id -> ItemData
var skill_effects: Dictionary = {}  # id -> BaseItemEffect

# Upgrades
var upgrades: Dictionary = {}  # StringName -> int

# Resources
var current_health: int = 6
var max_health: int = 6
var current_magic: int = 0
var max_magic: int = 128
var heart_pieces: int = 0
var rupees: int = 0
var arrows: int = 0
var bombs: int = 0
var dungeon_small_keys: Dictionary = {}  # dungeon_id -> int

# Bottles
var bottle_count: int = 0
var bottles: Array[int] = [0, 0, 0, 0]


func _ready() -> void:
	_emit_initial_state()


func _emit_initial_state() -> void:
	EventBus.player_health_changed.emit(current_health, max_health)
	EventBus.player_rupees_changed.emit(rupees)
	EventBus.player_magic_changed.emit(current_magic, max_magic)


# --- Acquisition ---

func acquire(item: ItemData) -> void:
	match item.item_type:
		ItemData.ItemType.SKILL:
			_acquire_skill(item)
		ItemData.ItemType.UPGRADE:
			_acquire_upgrade(item)
		ItemData.ItemType.RESOURCE:
			_acquire_resource(item)
	EventBus.item_acquired.emit(item.id)


func _acquire_skill(item: ItemData) -> void:
	if owned_skills.has(item.id):
		return
	owned_skills[item.id] = item
	if item.use_script:
		var effect: BaseItemEffect = item.use_script.new()
		skill_effects[item.id] = effect
	if equipped_skill_id == &"":
		equipped_skill_id = item.id


func _acquire_upgrade(item: ItemData) -> void:
	var current_tier: int = upgrades.get(item.upgrade_key, 0)
	upgrades[item.upgrade_key] = maxi(current_tier, item.tier)


func _acquire_resource(item: ItemData) -> void:
	match item.resource_key:
		&"rupees":
			rupees += item.resource_amount
			EventBus.player_rupees_changed.emit(rupees)
		&"arrows":
			arrows += item.resource_amount
		&"bombs":
			bombs += item.resource_amount
		&"hearts":
			heal(item.resource_amount)
		&"magic":
			current_magic = mini(current_magic + item.resource_amount, max_magic)
			EventBus.player_magic_changed.emit(current_magic, max_magic)
		&"heart_piece":
			heart_pieces += item.resource_amount
			if heart_pieces >= 4:
				heart_pieces -= 4
				max_health += 2
				current_health = max_health
				EventBus.player_health_changed.emit(current_health, max_health)
		&"small_key":
			var dungeon_id: StringName = SceneManager.current_room_data.dungeon_id if SceneManager.current_room_data else &""
			add_small_key(dungeon_id, item.resource_amount)
		&"big_key", &"map", &"compass":
			var dungeon_id: StringName = SceneManager.current_room_data.dungeon_id if SceneManager.current_room_data else &""
			GameManager.set_flag("%s/has_%s" % [dungeon_id, item.resource_key], true)


# --- Skills ---

func equip_skill(skill_id: StringName) -> void:
	if owned_skills.has(skill_id):
		equipped_skill_id = skill_id


func get_equipped_skill() -> ItemData:
	return owned_skills.get(equipped_skill_id, null)


func get_equipped_effect() -> BaseItemEffect:
	return skill_effects.get(equipped_skill_id, null)


func has_skill(skill_id: StringName) -> bool:
	return owned_skills.has(skill_id)


func get_owned_skills() -> Dictionary:
	return owned_skills


# --- Upgrades ---

func get_upgrade(key: StringName) -> int:
	return upgrades.get(key, 0)


func has_upgrade(key: StringName) -> bool:
	return get_upgrade(key) > 0


func reduce_upgrade(key: StringName, new_tier: int) -> void:
	if upgrades.has(key):
		upgrades[key] = new_tier


# --- Resources ---

func apply_damage(amount: int) -> void:
	current_health = maxi(current_health - amount, 0)
	EventBus.player_health_changed.emit(current_health, max_health)
	EventBus.player_damaged.emit(amount, 0)
	if current_health <= 0:
		EventBus.player_died.emit()


func heal(amount: int) -> void:
	current_health = mini(current_health + amount, max_health)
	EventBus.player_health_changed.emit(current_health, max_health)


func spend_rupees(amount: int) -> bool:
	if rupees < amount:
		return false
	rupees -= amount
	EventBus.player_rupees_changed.emit(rupees)
	return true


func spend_ammo(kind: StringName, amount: int) -> bool:
	match kind:
		&"arrows":
			if arrows < amount:
				return false
			arrows -= amount
			return true
		&"bombs":
			if bombs < amount:
				return false
			bombs -= amount
			return true
	return false


func consume_skill_cost(item: ItemData) -> bool:
	if item.magic_cost > 0 and current_magic < item.magic_cost:
		return false
	if item.ammo_type != &"" and item.ammo_cost > 0:
		if not spend_ammo(item.ammo_type, item.ammo_cost):
			return false
	if item.magic_cost > 0:
		current_magic -= item.magic_cost
		EventBus.player_magic_changed.emit(current_magic, max_magic)
	return true


# --- Small Keys ---

func add_small_key(dungeon_id: StringName, amount: int = 1) -> void:
	if not dungeon_small_keys.has(dungeon_id):
		dungeon_small_keys[dungeon_id] = 0
	dungeon_small_keys[dungeon_id] += amount


func use_small_key(dungeon_id: StringName) -> bool:
	var count: int = dungeon_small_keys.get(dungeon_id, 0)
	if count <= 0:
		return false
	dungeon_small_keys[dungeon_id] = count - 1
	return true


# --- Bottles ---

func add_bottle() -> bool:
	if bottle_count >= 4:
		return false
	bottle_count += 1
	return true


func set_bottle_contents(slot: int, contents: BottleContents) -> void:
	if slot >= 0 and slot < bottle_count:
		bottles[slot] = contents


func get_bottle_contents(slot: int) -> BottleContents:
	if slot >= 0 and slot < bottle_count:
		return bottles[slot] as BottleContents
	return BottleContents.EMPTY

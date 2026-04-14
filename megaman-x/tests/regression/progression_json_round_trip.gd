extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	Progression.reset_for_new_game()
	Progression.defeated_bosses = {&"chill_penguin": true}
	Progression.unlocked_weapons = {
		&"buster": true,
		&"shotgun_ice": true,
	}
	Progression.collected_pickups = {&"intro_capsule": true}
	Progression.collected_heart_tanks = {&"intro_heart": true}
	Progression.armor_parts = {
		&"helmet": true,
		&"body": false,
		&"arms": true,
		&"legs": false,
	}
	Progression.sub_tanks = {&"sub_tank_a": {"owned": true, "fill": 8}}

	var encoded_payload := JSON.stringify(Progression.to_dict())
	var parsed_payload := JSON.parse_string(encoded_payload)
	if typeof(parsed_payload) != TYPE_DICTIONARY:
		push_error("Progression JSON round-trip did not produce a dictionary payload.")
		quit(1)
		return

	Progression.from_dict(parsed_payload as Dictionary)

	if not Progression.unlocked_weapons.has(&"buster"):
		push_error("Unlocked weapons lost the buster StringName key after JSON round-trip.")
		quit(1)
		return

	if not Progression.unlocked_weapons.has(&"shotgun_ice"):
		push_error("Unlocked weapons lost a loaded StringName key after JSON round-trip.")
		quit(1)
		return

	if not Progression.defeated_bosses.has(&"chill_penguin"):
		push_error("Defeated bosses lost StringName keys after JSON round-trip.")
		quit(1)
		return

	if not Progression.collected_pickups.has(&"intro_capsule"):
		push_error("Collected pickups lost StringName keys after JSON round-trip.")
		quit(1)
		return

	if not Progression.collected_heart_tanks.has(&"intro_heart"):
		push_error("Collected heart tanks lost StringName keys after JSON round-trip.")
		quit(1)
		return

	if not Progression.armor_parts.has(&"helmet") or not Progression.armor_parts.has(&"arms"):
		push_error("Armor parts lost StringName keys after JSON round-trip.")
		quit(1)
		return

	if not Progression.sub_tanks.has(&"sub_tank_a"):
		push_error("Sub tanks lost StringName keys after JSON round-trip.")
		quit(1)
		return

	quit(0)

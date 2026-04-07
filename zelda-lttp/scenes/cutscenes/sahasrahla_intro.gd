class_name SahasrahlaIntroCutscene extends RefCounted

## Example NPC cutscene exercising camera pan, dialog, and SFX.


static func play(npc: Node2D, player: Node2D, camera: Camera2D) -> void:
	Cutscene.start()
	await Cutscene.wait(0.2)
	await Cutscene.camera_pan(camera, npc.global_position, 0.4)
	Cutscene.sfx(&"npc_appear")
	await Cutscene.wait(0.3)
	await Cutscene.dialog(PackedStringArray([
		"Ah, you must be the one...",
		"The legend speaks of a hero clad in green.",
		"Find the three pendants.",
	]))
	await Cutscene.camera_pan(camera, player.global_position, 0.4)
	Cutscene.camera_follow(camera, player)
	await Cutscene.wait(0.2)
	Cutscene.finish()

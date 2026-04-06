class_name RoomData extends Resource

@export var room_id: StringName
@export var scene_path: String
@export var room_type: StringName  # "overworld", "cave", "dungeon"
@export var dungeon_id: StringName
@export var world_type: StringName  # "light", "dark", "interior"
@export var screen_coords: Vector2i
@export var music_track: StringName
@export var ambient_color: Color = Color(1.0, 0.98, 0.9)
@export var is_dark_room: bool = false
@export var is_safe_respawn_point: bool = false
@export var neighbor_ids: Dictionary  # "up"/"down"/"left"/"right" -> room_id StringName

class_name DungeonData extends Resource

@export var dungeon_id: StringName
@export var dungeon_name: String
@export var rooms: Dictionary = {}  # Vector2i -> room_id (StringName); serialized as "x,y" -> room_id
@export var starting_room: Vector2i = Vector2i.ZERO
@export var boss_room: Vector2i = Vector2i.ZERO
@export var boss_id: StringName = &""
@export var floor_count: int = 1
@export var music_track: StringName = &""
@export var boss_music_track: StringName = &""

class_name Room extends Node2D

@export var room_data: RoomData

var dungeon_id: StringName:
	get:
		return room_data.dungeon_id if room_data else &""


func get_room_data() -> RoomData:
	return room_data


func get_neighbor(direction: StringName) -> StringName:
	if room_data and room_data.neighbor_ids.has(direction):
		return room_data.neighbor_ids[direction]
	return &""

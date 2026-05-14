class_name DropEntry
extends Resource

enum DropType { NOTHING, SMALL_ENERGY, LARGE_ENERGY, MISSILE, SUPER_MISSILE, POWER_BOMB }

@export var type: DropType = DropType.NOTHING
@export var weight: int = 0
@export var scene: PackedScene

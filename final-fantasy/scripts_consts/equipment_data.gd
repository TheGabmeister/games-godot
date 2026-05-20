class_name EquipmentData
extends Resource

enum Slot { WEAPON, SHIELD, BODY, HEAD, ARMS }

@export var equip_name: String
@export var slot: Slot
@export var attack_power: int
@export var absorb: int
@export var evade_penalty: int
@export var hit_percent: int
@export var weapon_index: int
@export var price: int

class_name ItemData
extends Resource

enum EffectType { HEAL_HP, RESTORE_CHARGES }

@export var item_name: String
@export var description: String
@export var effect_type: EffectType
@export var potency: int
@export var price: int

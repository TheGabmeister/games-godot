class_name SpellData
extends Resource

enum Element { NONE = -1, FIRE, ICE, LIGHTNING, EARTH, POISON, TIME, DEATH, STATUS }
enum TargetType { SINGLE_ENEMY, ALL_ENEMIES, SINGLE_ALLY, ALL_ALLIES, SELF }
enum SpellEffect { DAMAGE, HEAL, BUFF, DEBUFF, STATUS_INFLICT, STATUS_CURE }

@export var spell_name: String
@export var level: int
@export var spell_accuracy: int
@export var element: Element = Element.NONE
@export var target_type: TargetType
@export var effects: Array[SpellEffectEntry] = []
@export var is_white_magic: bool

class_name DamageType

enum Type {
	CONTACT,
	SWORD,
	ARROW,
	BOMB,
	FIRE,
	ICE,
	MAGIC,
	PIT,
	WATER,
	SPIKE,
}

enum HitEffect {
	NONE,
	STUN,
	FREEZE,
	BURN,
}

## Environmental damage types that bypass armor entirely.
const ENVIRONMENTAL_TYPES: Array[int] = [Type.PIT, Type.WATER, Type.SPIKE]

## Combat damage types that armor can reduce.
const COMBAT_TYPES: Array[int] = [Type.CONTACT, Type.SWORD, Type.ARROW, Type.BOMB, Type.FIRE, Type.ICE, Type.MAGIC]

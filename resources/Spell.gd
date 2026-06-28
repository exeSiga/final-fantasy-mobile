extends Resource
class_name Spell

enum EffectType { DAMAGE, HEAL, HASTE }

@export var spell_name: String = ""
@export var mp_cost: int = 0
@export var damage_multiplier: float = 1.0
@export var effect_type: EffectType = EffectType.DAMAGE
@export var description: String = ""

extends Resource
class_name Item

enum EffectType { HEAL_HP, HEAL_MP, REVIVE, MATERIAL }

@export var item_name: String = ""
@export var description: String = ""
@export var effect_type: EffectType = EffectType.HEAL_HP
@export var effect_value: int = 0
@export var price: int = 0
@export var max_stack: int = 9

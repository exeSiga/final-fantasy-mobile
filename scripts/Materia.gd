extends Resource
class_name Materia

@export var materia_name: String = ""
@export var materia_type: String = ""   # "spell", "passive", "summon", or "enemy_skill"
@export var spell_path: String = ""     # for spell type
@export var passive_stat: String = ""   # "hp" or "mp" for passive type
@export var passive_pct: float = 0.3   # 30% bonus
@export var price: int = 500
@export var description: String = ""

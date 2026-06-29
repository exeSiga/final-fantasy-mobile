extends Resource

@export var equip_name: String = ""
@export var slot: int = 0         # 0 = WEAPON, 1 = ARMOR
@export var stat_bonus: int = 0
@export var price: int = 0
@export var allowed_classes: Array = []   # e.g. ["Warrior"] — empty = all
@export var description: String = ""
@export var materia_slots: int = 0

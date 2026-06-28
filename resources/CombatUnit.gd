extends Resource
class_name CombatUnit

@export var unit_name: String = ""
@export var hp: int = 0
@export var max_hp: int = 0
@export var mp: int = 0
@export var max_mp: int = 0
@export var atk: int = 0
@export var def: int = 0
@export var spd: int = 0
@export var is_player: bool = false
@export var sprite_color: Color = Color.WHITE

func is_alive() -> bool:
	return hp > 0

func take_damage(amount: int) -> int:
	var actual := max(1, amount - def)
	hp = max(0, hp - actual)
	return actual

func calc_damage_against(target: CombatUnit) -> int:
	return max(1, atk - target.def)

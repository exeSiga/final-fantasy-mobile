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
@export var level: int = 1
@export var xp: int = 0
@export var xp_to_next_level: int = 100
@export var xp_reward: int = 0
@export var gold_reward: int = 0

func is_alive() -> bool:
	return hp > 0

func take_damage(amount: int) -> int:
	var actual: int = max(1, amount - def)
	hp = max(0, hp - actual)
	return actual

func calc_damage_against(target: CombatUnit) -> int:
	return max(1, atk - target.def)

func add_xp(amount: int) -> bool:
	xp += amount
	if xp >= xp_to_next_level:
		xp -= xp_to_next_level
		level += 1
		max_hp += 20
		hp = max_hp
		atk += 3
		def += 2
		spd += 1
		xp_to_next_level = int(xp_to_next_level * 1.4)
		return true
	return false

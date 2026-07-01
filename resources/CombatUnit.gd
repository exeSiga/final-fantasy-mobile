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
@export var character_class: String = ""
@export var element_weakness: String = ""
@export var spell_paths: Array = []

# Runtime state (not saved to .tres)
var haste_turns_left: int = 0
var base_spd: int = 0
var status: String = ""       # "" | "poison" | "sleep" | "silence"
var status_turns: int = 0
var limit_gauge: int = 0      # 0-100, fills when receiving damage
var limit_damage_taken: int = 0  # cumulative damage taken; at 200 → tier 2 unlocks
var limit_tier: int = 1           # 1 or 2; tier 2 unlocked at limit_damage_taken >= 200
var current_phase: int = 0   # boss phase tracker
var spell_immune: bool = false  # blocks player spells (boss phase 2)
var atb_gauge: float = 0.0    # 0-100 ATB charge, fills based on spd before the unit can act

const STATUS_MAX_TURNS := 3

func is_alive() -> bool:
	return hp > 0

func inflict_status(s: String) -> bool:
	if status != "":
		return false  # already afflicted
	status = s
	status_turns = STATUS_MAX_TURNS
	return true

func clear_status() -> void:
	status = ""
	status_turns = 0

func tick_status() -> int:
	# Returns poison damage dealt, or 0 for other statuses
	if status == "":
		return 0
	status_turns -= 1
	if status_turns <= 0:
		clear_status()
		return 0
	if status == "poison":
		var dmg: int = max(1, int(max_hp * 0.07))
		hp = max(0, hp - dmg)
		return dmg
	return 0

func take_damage(amount: int) -> int:
	var actual: int = max(1, amount - def)
	hp = max(0, hp - actual)
	return actual

func take_damage_ignore_def(amount: int) -> int:
	hp = max(0, hp - amount)
	return amount

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
		if base_spd > 0:
			base_spd += 1
		xp_to_next_level = int(xp_to_next_level * 1.4)
		return true
	return false

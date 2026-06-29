extends Node

signal quest_completed(quest_id: String)

const QUESTS := [
	{
		"quest_id": "goblin_threat",
		"quest_name": "Menace Gobelin",
		"description": "Éliminer 5 Gobelins qui terrorisent Midgar.",
		"target_enemy": "Goblin",
		"target_count": 5,
		"reward_gold": 300,
		"reward_xp": 0,
		"reward_item_path": "",
	},
	{
		"quest_id": "lost_blade",
		"quest_name": "Lame Perdue",
		"description": "Vaincre 3 Orcs pour récupérer la Long Sword.",
		"target_enemy": "Orc",
		"target_count": 3,
		"reward_gold": 0,
		"reward_xp": 0,
		"reward_item_path": "res://resources/equipment/long_sword.tres",
	},
	{
		"quest_id": "protect_kalm",
		"quest_name": "Protéger Kalm",
		"description": "Vaincre le Guard Scorpion qui menace Kalm.",
		"target_enemy": "Guard Scorpion",
		"target_count": 1,
		"reward_gold": 0,
		"reward_xp": 500,
		"reward_item_path": "",
	},
]

var kill_counts: Dictionary = {}   # enemy_name → count
var completed: Dictionary = {}     # quest_id → bool

func notify_kill(enemy_name: String) -> void:
	kill_counts[enemy_name] = kill_counts.get(enemy_name, 0) + 1
	_check_completions()

func _check_completions() -> void:
	for q in QUESTS:
		var qid: String = q.quest_id
		if completed.get(qid, false):
			continue
		var kills: int = kill_counts.get(q.target_enemy, 0)
		if kills >= q.target_count:
			_complete_quest(q)

func _complete_quest(q: Dictionary) -> void:
	var qid: String = q.quest_id
	completed[qid] = true
	if q.reward_gold > 0:
		GameManager.add_gold(q.reward_gold)
	if q.reward_xp > 0:
		for m in GameManager.alive_party():
			m.add_xp(q.reward_xp)
	if q.reward_item_path != "":
		var item = load(q.reward_item_path)
		if item != null:
			GameManager.equip_inventory[q.reward_item_path] = GameManager.equip_inventory.get(q.reward_item_path, 0) + 1
	quest_completed.emit(qid)

func get_quest_data(quest_id: String) -> Dictionary:
	for q in QUESTS:
		if q.quest_id == quest_id:
			return q
	return {}

func progress(quest_id: String) -> int:
	var q: Dictionary = get_quest_data(quest_id)
	if q.is_empty():
		return 0
	return kill_counts.get(q.target_enemy, 0)

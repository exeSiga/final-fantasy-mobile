extends Node

enum GameState { MAIN_MENU, WORLD, BATTLE, CUTSCENE, GAME_OVER }

const CRAFT_RECIPES: Array = [
	{
		"name": "Buster Sword+",
		"ingredients": {"res://resources/items/scrap_metal.tres": 2},
		"result": "res://resources/equipment/buster_sword_plus.tres",
		"result_type": "equip",
	},
	{
		"name": "Mako Bracelet",
		"ingredients": {"res://resources/items/mako_crystal.tres": 2},
		"result": "res://resources/equipment/mako_bracelet.tres",
		"result_type": "equip",
	},
	{
		"name": "Ether",
		"ingredients": {
			"res://resources/items/monster_fang.tres": 1,
			"res://resources/items/magic_ore.tres": 1,
		},
		"result": "res://resources/items/ether.tres",
		"result_type": "item",
	},
]

var current_state: GameState = GameState.MAIN_MENU
var current_scene: Node = null
var party: Array = []              # 3 active CombatUnit
var available_members: Array = []  # 6+ CombatUnit: [Cloud, Tifa, Aerith, Barret, Red XIII, Yuffie]
var active_party_indices: Array = [0, 1, 2]  # which 3 of 4 are active
var player_unit = null             # alias for party[0] — kept for compatibility
var gold: int = 0
var inventory: Dictionary = {}
var equip_inventory: Dictionary = {}   # resource_path → count (unequipped gear owned)
var equipment: Array = [               # one dict per party member
	{"weapon": null, "armor": null},
	{"weapon": null, "armor": null},
	{"weapon": null, "armor": null},
]
var materia_inventory: Dictionary = {} # resource_path → count
var materia_equipped: Dictionary = {}  # "member_weapon_0" → resource_path
var learned_enemy_skills: Array = []   # Array of spell resource_paths learned via Enemy Skill Materia
var summon_charges: Dictionary = {}    # materia_path → charges_left (reset each battle)
var base_party_spell_paths: Array = [[], [], []]
var return_after_battle: String = "res://scenes/world/WorldMap.tscn"
var dungeon_boss_cleared = false
var dungeon_return_room: int = -1
var active_zone: String = "midgar"
var story_intro_done: bool = false
var scene_reactor_done: bool = false
var scene_jenova_done: bool = false
var sephiroth_defeated: bool = false
var total_kills: int = 0
var shinra_files_seen: Array = []

const SHINRA_FILES: Array = [
	{
		"id": "first_slime",
		"title": "Fichier ShinRa #001 — Créature Mako",
		"lore": "Les Slimes sont des résidus de Mako qui mutent dans les conduits des réacteurs abandonnés.",
	},
	{
		"id": "guard_scorpion",
		"title": "Fichier ShinRa #002 — Unité Guard Scorpion",
		"lore": "Le Guard Scorpion est un proto-arme ShinRa déployé dans les réacteurs Mako prioritaires.",
	},
	{
		"id": "rank_2nd",
		"title": "Fichier ShinRa #003 — Rang SOLDIER 2nd Class",
		"lore": "Un SOLDIER de 2nd Class a prouvé sa valeur au combat. ShinRa note ces agents pour promotion.",
	},
	{
		"id": "jenova",
		"title": "Fichier ShinRa #004 — Projet Jenova [CLASSIFIÉ]",
		"lore": "Le projet J. implique un être extraterrestre découvert sous Nibelheim. Dossier top secret — accès refusé.",
	},
	{
		"id": "kills_25",
		"title": "Fichier ShinRa #005 — Rapport d'engagements",
		"lore": "25 ennemis neutralisés. Ce soldat est opérationnel. Recommandation : promotion à l'étude.",
	},
	{
		"id": "sephiroth",
		"title": "Fichier ShinRa #006 — Incident Sephiroth [ULTRA-CLASSIFIÉ]",
		"lore": "Sephiroth... ce nom ne doit plus jamais être prononcé dans les rangs de ShinRa. Dossier scellé.",
	},
]
const ENEMY_STEAL_POOL: Dictionary = {
	"Slime":          "res://resources/items/potion.tres",
	"Goblin":         "res://resources/items/potion.tres",
	"Skeleton":       "res://resources/items/phoenix_down.tres",
	"Bat":            "res://resources/items/potion.tres",
	"Orc":            "res://resources/items/mako_crystal.tres",
	"Shadow":         "res://resources/items/ether.tres",
	"Troll":          "res://resources/items/monster_fang.tres",
	"Gargoyle":       "res://resources/items/magic_ore.tres",
	"Dark Knight":    "res://resources/items/ether.tres",
	"Guard Scorpion": "res://resources/items/mako_shard.tres",
	"Jenova":         "res://resources/items/phoenix_down.tres",
	"Sephiroth":      "res://resources/items/hi_potion.tres",
	"Ruby Weapon":    "res://resources/items/hi_potion.tres",
	"Emerald Weapon": "res://resources/items/hi_potion.tres",
}
const DUNGEON_TREASURE_POOL: Array = [
	"res://resources/equipment/dark_matter_armlet.tres",
	"res://resources/equipment/warrior_bangle.tres",
	"res://resources/equipment/gigas_armlet.tres",
	"res://resources/equipment/crystal_sword.tres",
]

const BESTIARY: Dictionary = {
	"Slime":          {"lore": "Résidu de Mako muté. La base de l'écosystème hostile des réacteurs.", "base_hp": 30,  "base_atk": 8,  "milestone": 10, "milestone_item": "res://resources/items/potion.tres"},
	"Goblin":         {"lore": "Creature agressive des bas-fonds. Adepte des coups sournois et de la paralysie.", "base_hp": 45,  "base_atk": 12, "milestone": 10, "milestone_item": "res://resources/items/hi_potion.tres"},
	"Skeleton":       {"lore": "Guerrier déchu animé par le Mako noir. Insensible à la douleur.", "base_hp": 55,  "base_atk": 14, "milestone": 10, "milestone_item": "res://resources/items/ether.tres"},
	"Bat":            {"lore": "Créature des cavernes sombres. Son ultrason perturbe les incantations magiques.", "base_hp": 40,  "base_atk": 10, "milestone": 10, "milestone_item": "res://resources/items/phoenix_down.tres"},
	"Orc":            {"lore": "Bête sauvage des collines de Kalm. Sa cri de guerre booste temporairement sa puissance.", "base_hp": 80,  "base_atk": 18, "milestone": 10, "milestone_item": "res://resources/items/mako_shard.tres"},
	"Shadow":         {"lore": "Entité spectrale qui draine le MP. On dit qu'elle est née des expériences ShinRa.", "base_hp": 70,  "base_atk": 16, "milestone": 10, "milestone_item": "res://resources/items/ether.tres"},
	"Troll":          {"lore": "Géant régénérant des montagnes. Sa peau épaisse résiste à la plupart des lames.", "base_hp": 120, "base_atk": 22, "milestone": 10, "milestone_item": "res://resources/items/hi_potion.tres"},
	"Gargoyle":       {"lore": "Gardien de pierre des ruines ShinRa. Son regard pétrifiant est redouté des aventuriers.", "base_hp": 100, "base_atk": 20, "milestone": 10, "milestone_item": "res://resources/items/mako_crystal.tres"},
	"Dark Knight":    {"lore": "Prototype SOLDIER raté, abandonné par ShinRa. Maîtrise des attaques de ténèbres.", "base_hp": 200, "base_atk": 30, "milestone": 5,  "milestone_item": "res://resources/items/ether.tres"},
	"Guard Scorpion": {"lore": "Arme ShinRa déployée dans les réacteurs. Phase 2 : laser de queue dévastateur.", "base_hp": 800, "base_atk": 30, "milestone": 1,  "milestone_item": "res://resources/items/hi_potion.tres"},
	"MP Soldier":     {"lore": "Soldat ShinRa de base. Discipliné, peu imaginatif, mais toujours en groupe.", "base_hp": 60,  "base_atk": 13, "milestone": 10, "milestone_item": "res://resources/items/potion.tres"},
	"Hedgehog Pie":   {"lore": "Mutant des Slums de Midgar. Son pelage hérissé peut retourner les dégâts.", "base_hp": 50,  "base_atk": 11, "milestone": 10, "milestone_item": "res://resources/items/slum_herb.tres"},
	"Shinra Guard":   {"lore": "Garde d'élite du Secteur 7. Mieux équipé que les soldats standards.", "base_hp": 70,  "base_atk": 15, "milestone": 10, "milestone_item": "res://resources/items/mako_shard.tres"},
}
var bestiary_milestones_given: Dictionary = {}

const MATERIA_AP_THRESHOLDS: Dictionary = {
	"res://resources/materias/fire_materia.tres":     [80, 250],
	"res://resources/materias/blizzard_materia.tres": [80, 250],
	"res://resources/materias/thunder_materia.tres":  [80, 250],
}
const MATERIA_SPELL_TIERS: Dictionary = {
	"res://resources/materias/fire_materia.tres": [
		"res://resources/spells/fire.tres",
		"res://resources/spells/fira.tres",
		"res://resources/spells/firaga.tres",
	],
	"res://resources/materias/blizzard_materia.tres": [
		"res://resources/spells/blizzard.tres",
		"res://resources/spells/blizzara.tres",
		"res://resources/spells/blizzaga.tres",
	],
	"res://resources/materias/thunder_materia.tres": [
		"res://resources/spells/thunder.tres",
		"res://resources/spells/thundara.tres",
		"res://resources/spells/thundaga.tres",
	],
}
var materia_ap: Dictionary = {}

func get_materia_level(mat_path: String) -> int:
	var thresholds: Array = MATERIA_AP_THRESHOLDS.get(mat_path, [])
	if thresholds.is_empty():
		return 1
	var ap: int = materia_ap.get(mat_path, 0)
	if ap >= thresholds[1]:
		return 3
	if ap >= thresholds[0]:
		return 2
	return 1

func grant_materia_ap(amount: int) -> void:
	for key in materia_equipped:
		var mat_path: String = materia_equipped[key]
		if mat_path != "" and MATERIA_AP_THRESHOLDS.has(mat_path):
			materia_ap[mat_path] = materia_ap.get(mat_path, 0) + amount

const WALL_MARKET_ITEMS: Array = [
	{"path": "res://resources/items/hi_potion.tres",         "price": 300,  "type": "item"},
	{"path": "res://resources/items/x_potion.tres",          "price": 800,  "type": "item"},
	{"path": "res://resources/items/ether.tres",             "price": 500,  "type": "item"},
	{"path": "res://resources/items/megalixir.tres",         "price": 2000, "type": "item"},
	{"path": "res://resources/items/remedy.tres",            "price": 400,  "type": "item"},
	{"path": "res://resources/equipment/carbon_bangle.tres", "price": 1200, "type": "equip"},
]
const WALL_MARKET_DEAL_ITEMS: Array = [
	"res://resources/items/phoenix_down.tres",
	"res://resources/items/mako_shard.tres",
	"res://resources/items/magic_ore.tres",
	"res://resources/items/ether.tres",
]
const WALL_MARKET_UNLOCK_ITEM: String = "res://resources/equipment/black_materia_shard.tres"
var wall_market_visits: int = 0
var dungeon_treasures_found: Array = []
var boss_rush_best_score: int = 0
var boss_rush_active: bool = false
var ng_plus_unlocked: bool = false
var ng_plus_mode: bool = false
var npc_flags: Dictionary = {}
var shop_last_rank: String = "3rd Class"
var pending_rank_notification: String = ""

const NPC_CHOICES: Dictionary = {
	"npc_guide": {
		"title": "Habitant de Midgar",
		"text": "Aventurier ! Tu m'as l'air courageux. Que veux-tu que je t'offre ?",
		"choices": [
			{"label": "De l'or.", "reward": "gold", "value": 200},
			{"label": "Une Potion.", "reward": "item", "path": "res://resources/items/potion.tres"},
		],
		"done_text": "Reviens si tu as besoin, aventurier.",
	},
	"npc_soldier": {
		"title": "Soldat ShinRa",
		"text": "Halt ! Quel est l'ennemi le plus dangereux de Midgar ?",
		"choices": [
			{"label": "Le Guard Scorpion.", "reward": "gold", "value": 300},
			{"label": "Un simple Slime.", "reward": "lore", "message": "Mauvaise réponse... Mais je t'offre quand même 50G. La prochaine fois, lis les rapports ShinRa."},
		],
		"done_text": "Tu peux passer. ShinRa t'a à l'œil.",
	},
	"npc_innkeeper": {
		"title": "Vendeur Ambulant",
		"text": "Pssst ! J'ai quelque chose de spécial. Tu veux un tuyau ou un objet rare ?",
		"choices": [
			{"label": "L'objet rare.", "reward": "item", "path": "res://resources/items/ether.tres"},
			{"label": "Le tuyau.", "reward": "lore", "message": "Le tuyau : les Matérias de type Sorts augmentent l'ATK magique. Équipe-en plusieurs !"},
		],
		"done_text": "On a déjà fait affaire. À plus !",
	},
}
var merchant_discount: float = 1.0

signal gold_changed(new_amount: int)
signal level_up(new_level: int)
signal rank_changed(new_rank: String)

func _ready() -> void:
	get_tree().root.child_entered_tree.connect(_on_root_child_entered)

func _on_root_child_entered(node: Node) -> void:
	current_scene = node

func change_scene(path: String) -> void:
	TransitionManager.fade_to(path)

func set_state(new_state: GameState) -> void:
	current_state = new_state

func rebuild_party_from_indices() -> void:
	party.clear()
	for idx in active_party_indices:
		if idx < available_members.size():
			party.append(available_members[idx])
	player_unit = party[0] if not party.is_empty() else null
	base_party_spell_paths = []
	for m in party:
		base_party_spell_paths.append(m.spell_paths.duplicate())

func set_active_party_indices(indices: Array) -> void:
	if indices.size() != 3:
		return
	var seen: Dictionary = {}
	for idx in indices:
		if idx < 0 or idx >= available_members.size() or seen.has(idx):
			return
		seen[idx] = true
	active_party_indices = indices.duplicate()
	rebuild_party_from_indices()

func new_game() -> void:
	available_members.clear()
	party.clear()
	var warrior = load("res://resources/units/hero.tres").duplicate()
	var black_mage = load("res://resources/units/black_mage.tres").duplicate()
	var white_mage = load("res://resources/units/white_mage.tres").duplicate()
	var barret = load("res://resources/units/barret.tres").duplicate()
	var red_xiii = load("res://resources/units/red_xiii.tres").duplicate()
	var yuffie = load("res://resources/units/yuffie.tres").duplicate()
	var vincent = load("res://resources/units/vincent.tres").duplicate()
	var cait_sith = load("res://resources/units/cait_sith.tres").duplicate()
	available_members = [warrior, black_mage, white_mage, barret, red_xiii, yuffie, vincent, cait_sith]
	active_party_indices = [0, 1, 2]
	party.append(warrior)
	party.append(black_mage)
	party.append(white_mage)
	player_unit = warrior
	gold = 0
	inventory = {}
	equip_inventory = {}
	equipment = [
		{"weapon": null, "armor": null},
		{"weapon": null, "armor": null},
		{"weapon": null, "armor": null},
	]
	materia_inventory = {}
	materia_equipped = {}
	learned_enemy_skills = []
	summon_charges = {}
	base_party_spell_paths = []
	active_zone = "midgar"
	story_intro_done = false
	scene_reactor_done = false
	scene_jenova_done = false
	sephiroth_defeated = false
	shinra_files_seen = []
	total_kills = 0
	dungeon_treasures_found = []
	ng_plus_unlocked = false
	ng_plus_mode = false
	npc_flags = {}
	bestiary_milestones_given = {}
	shop_last_rank = "3rd Class"
	pending_rank_notification = ""
	materia_ap = {}
	wall_market_visits = 0
	boss_rush_active = false
	boss_rush_best_score = 0
	for m in party:
		base_party_spell_paths.append(m.spell_paths.duplicate())
	dungeon_boss_cleared = false
	dungeon_return_room = -1

func alive_party() -> Array:
	return party.filter(func(m) -> bool: return m.is_alive())

func check_shinra_files() -> void:
	for entry in SHINRA_FILES:
		if entry.id in shinra_files_seen:
			continue
		if _check_shinra_condition(entry.id):
			shinra_files_seen.append(entry.id)
			_show_shinra_popup(entry.title, entry.lore)

func _check_shinra_condition(file_id: String) -> bool:
	match file_id:
		"first_slime":    return QuestManager.kill_counts.get("Slime", 0) >= 1
		"guard_scorpion": return scene_reactor_done
		"rank_2nd":       return total_kills >= 50
		"jenova":         return scene_jenova_done
		"kills_25":       return total_kills >= 25
		"sephiroth":      return sephiroth_defeated
	return false

func _show_shinra_popup(title: String, lore: String) -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 88
	get_tree().root.add_child(canvas)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_top = -220.0
	panel.offset_bottom = -10.0
	panel.offset_left = 10.0
	panel.offset_right = -10.0
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	var header := Label.new()
	header.text = "📁 " + title
	header.add_theme_font_size_override("font_size", 24)
	header.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0, 1))
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var lore_lbl := Label.new()
	lore_lbl.text = lore
	lore_lbl.add_theme_font_size_override("font_size", 20)
	lore_lbl.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0, 1))
	lore_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lore_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(header)
	vbox.add_child(lore_lbl)
	panel.add_child(vbox)
	canvas.add_child(panel)
	panel.gui_input.connect(func(ev): if ev is InputEventScreenTouch and ev.pressed: canvas.queue_free())
	await get_tree().create_timer(4.0).timeout
	if is_instance_valid(canvas):
		canvas.queue_free()

func try_show_dungeon_treasure() -> Node:
	var available: Array = DUNGEON_TREASURE_POOL.filter(func(p) -> bool: return p not in dungeon_treasures_found)
	if available.is_empty():
		return null
	var item_path: String = available[randi() % available.size()]
	dungeon_treasures_found.append(item_path)
	var item = load(item_path)
	if item == null:
		return null
	equip_inventory[item_path] = equip_inventory.get(item_path, 0) + 1
	var canvas := CanvasLayer.new()
	canvas.layer = 91
	get_tree().root.add_child(canvas)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -300.0
	panel.offset_right = 300.0
	panel.offset_top = -220.0
	panel.offset_bottom = 220.0
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	var icon_lbl := Label.new()
	icon_lbl.text = "💎"
	icon_lbl.add_theme_font_size_override("font_size", 64)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var title_lbl := Label.new()
	title_lbl.text = "Trésor !"
	title_lbl.add_theme_font_size_override("font_size", 36)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3, 1))
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var item_lbl := Label.new()
	var bonus_stat: String = "ATK" if item.slot == 0 else "DEF"
	item_lbl.text = "%s\n[+%d %s]" % [item.equip_name, item.stat_bonus, bonus_stat]
	item_lbl.add_theme_font_size_override("font_size", 28)
	item_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.7, 1))
	item_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var ok_btn := Button.new()
	ok_btn.text = "Prendre !"
	ok_btn.add_theme_font_size_override("font_size", 30)
	ok_btn.custom_minimum_size = Vector2(200, 70)
	ok_btn.pressed.connect(canvas.queue_free)
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_child(ok_btn)
	vbox.add_child(icon_lbl)
	vbox.add_child(title_lbl)
	vbox.add_child(item_lbl)
	vbox.add_child(btn_row)
	panel.add_child(vbox)
	canvas.add_child(panel)
	return canvas

func show_npc_choice(npc_id: String) -> void:
	var data: Dictionary = NPC_CHOICES.get(npc_id, {})
	if data.is_empty():
		return
	if npc_flags.get(npc_id, false):
		_show_npc_done_popup(data.get("done_text", "..."))
		return
	var canvas := CanvasLayer.new()
	canvas.layer = 90
	get_tree().root.add_child(canvas)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -320.0
	panel.offset_right = 320.0
	panel.offset_top = -200.0
	panel.offset_bottom = 200.0
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	var title_lbl := Label.new()
	title_lbl.text = data.title
	title_lbl.add_theme_font_size_override("font_size", 30)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4, 1))
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var text_lbl := Label.new()
	text_lbl.text = data.text
	text_lbl.add_theme_font_size_override("font_size", 24)
	text_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
	text_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_lbl)
	vbox.add_child(text_lbl)
	var choices: Array = data.get("choices", [])
	for choice in choices:
		var btn := Button.new()
		btn.text = choice.label
		btn.add_theme_font_size_override("font_size", 26)
		btn.custom_minimum_size = Vector2(0, 60)
		btn.pressed.connect(func():
			npc_flags[npc_id] = true
			canvas.queue_free()
			_apply_npc_reward(choice)
		)
		vbox.add_child(btn)
	panel.add_child(vbox)
	canvas.add_child(panel)

func _apply_npc_reward(choice: Dictionary) -> void:
	match choice.get("reward", ""):
		"gold":
			var amount: int = choice.get("value", 0)
			add_gold(amount)
			_show_npc_done_popup("+%d G !" % amount)
		"item":
			var item_path: String = choice.get("path", "")
			if item_path != "":
				var item = load(item_path)
				if item != null:
					add_item(item)
					_show_npc_done_popup("Reçu : %s !" % item.item_name)
		"lore":
			var msg: String = choice.get("message", "Merci de ton écoute.")
			_show_npc_done_popup(msg)

func _show_npc_done_popup(text: String) -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 90
	get_tree().root.add_child(canvas)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -280.0
	panel.offset_right = 280.0
	panel.offset_top = -100.0
	panel.offset_bottom = 100.0
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 26)
	lbl.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0, 1))
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(lbl)
	canvas.add_child(panel)
	panel.gui_input.connect(func(ev): if ev is InputEventScreenTouch and ev.pressed: canvas.queue_free())
	await get_tree().create_timer(3.0).timeout
	if is_instance_valid(canvas):
		canvas.queue_free()

func add_item(item: Resource, qty: int = 1) -> void:
	var key: String = item.resource_path
	inventory[key] = min(item.max_stack, inventory.get(key, 0) + qty)

func use_item(item: Resource) -> bool:
	var key: String = item.resource_path
	if inventory.get(key, 0) <= 0:
		return false
	var used := false
	match item.effect_type:
		0:  # HEAL_HP — target most injured alive member
			var target = _most_injured_hp()
			if target == null or target.hp >= target.max_hp:
				return false
			target.hp = min(target.max_hp, target.hp + item.effect_value)
			used = true
		1:  # HEAL_MP — target most depleted MP
			var target = _most_depleted_mp()
			if target == null or target.mp >= target.max_mp:
				return false
			target.mp = min(target.max_mp, target.mp + item.effect_value)
			used = true
		2:  # REVIVE — first dead member
			var target = _first_dead()
			if target == null:
				return false
			target.hp = item.effect_value
			used = true
		4:  # HEAL_ALL — restore all HP and MP for entire alive party
			var targets: Array = alive_party()
			if targets.is_empty():
				return false
			for m in targets:
				m.hp = m.max_hp
				m.mp = m.max_mp
			used = true
		5:  # CLEAR_STATUS — clear all statuses from alive party
			var targets: Array = alive_party()
			if targets.is_empty():
				return false
			for m in targets:
				m.clear_status()
			used = true
	if used:
		inventory[key] -= 1
		if inventory[key] <= 0:
			inventory.erase(key)
	return used

func _most_injured_hp():
	var best = null
	var best_pct: float = 1.0
	for m in alive_party():
		var pct: float = float(m.hp) / float(m.max_hp)
		if pct < best_pct:
			best_pct = pct
			best = m
	return best

func _most_depleted_mp():
	var best = null
	var best_pct: float = 1.0
	for m in alive_party():
		if m.max_mp <= 0:
			continue
		var pct: float = float(m.mp) / float(m.max_mp)
		if pct < best_pct:
			best_pct = pct
			best = m
	return best

func _first_dead():
	for m in party:
		if not m.is_alive():
			return m
	return null

func buy_equipment(item: Resource) -> bool:
	var cost: int = get_discounted_price(item.price)
	if gold < cost:
		return false
	gold -= cost
	gold_changed.emit(gold)
	var key: String = item.resource_path
	equip_inventory[key] = equip_inventory.get(key, 0) + 1
	return true

func equip(member_idx: int, item: Resource) -> bool:
	if member_idx < 0 or member_idx >= party.size():
		return false
	var member = party[member_idx]
	var slot_name: String = "weapon" if item.slot == 0 else "armor"
	if item.allowed_classes.size() > 0 and not item.allowed_classes.has(member.character_class):
		return false
	var key: String = item.resource_path
	if equip_inventory.get(key, 0) <= 0:
		return false
	equip_inventory[key] -= 1
	if equip_inventory[key] <= 0:
		equip_inventory.erase(key)
	var old_item = equipment[member_idx].get(slot_name)
	if old_item != null:
		_remove_equip_bonus(member, old_item)
		var old_key: String = old_item.resource_path
		equip_inventory[old_key] = equip_inventory.get(old_key, 0) + 1
	equipment[member_idx][slot_name] = item
	_apply_equip_bonus(member, item)
	return true

func unequip_slot(member_idx: int, slot_name: String) -> void:
	if member_idx < 0 or member_idx >= party.size():
		return
	var old_item = equipment[member_idx].get(slot_name)
	if old_item == null:
		return
	_remove_equip_bonus(party[member_idx], old_item)
	var key: String = old_item.resource_path
	equip_inventory[key] = equip_inventory.get(key, 0) + 1
	equipment[member_idx][slot_name] = null

func _apply_equip_bonus(member, item: Resource) -> void:
	if item.slot == 0:
		member.atk += item.stat_bonus
	else:
		member.def += item.stat_bonus

func _remove_equip_bonus(member, item: Resource) -> void:
	if item.slot == 0:
		member.atk -= item.stat_bonus
	else:
		member.def -= item.stat_bonus

func reset_summon_charges() -> void:
	for key in materia_equipped:
		var mat_path: String = materia_equipped[key]
		var mat = load(mat_path)
		if mat != null and mat.materia_type == "summon":
			summon_charges[mat_path] = 1

func buy_materia(mat: Resource) -> bool:
	var cost: int = get_discounted_price(mat.price)
	if gold < cost:
		return false
	gold -= cost
	gold_changed.emit(gold)
	var key: String = mat.resource_path
	materia_inventory[key] = materia_inventory.get(key, 0) + 1
	return true

func equip_materia(member_idx: int, slot_name: String, slot_idx: int, mat_path: String) -> bool:
	if member_idx < 0 or member_idx >= party.size():
		return false
	if materia_inventory.get(mat_path, 0) <= 0:
		return false
	var key: String = "%d_%s_%d" % [member_idx, slot_name, slot_idx]
	var old_path: String = materia_equipped.get(key, "")
	if old_path != "":
		unequip_materia(member_idx, slot_name, slot_idx)
	materia_inventory[mat_path] -= 1
	if materia_inventory[mat_path] <= 0:
		materia_inventory.erase(mat_path)
	materia_equipped[key] = mat_path
	var mat = load(mat_path)
	if mat != null and mat.materia_type == "passive":
		var member = party[member_idx]
		if mat.passive_stat == "hp":
			var bonus: int = int(member.max_hp * mat.passive_pct)
			member.max_hp += bonus
			member.hp = min(member.hp + bonus, member.max_hp)
		elif mat.passive_stat == "mp":
			var bonus: int = int(member.max_mp * mat.passive_pct)
			member.max_mp += bonus
			member.mp = min(member.mp + bonus, member.max_mp)
	return true

func unequip_materia(member_idx: int, slot_name: String, slot_idx: int) -> void:
	var key: String = "%d_%s_%d" % [member_idx, slot_name, slot_idx]
	var mat_path: String = materia_equipped.get(key, "")
	if mat_path == "":
		return
	materia_equipped.erase(key)
	materia_inventory[mat_path] = materia_inventory.get(mat_path, 0) + 1
	var mat = load(mat_path)
	if mat != null and mat.materia_type == "passive":
		var member = party[member_idx]
		if mat.passive_stat == "hp":
			var bonus: int = int(member.max_hp * mat.passive_pct / (1.0 + mat.passive_pct))
			member.max_hp = max(1, member.max_hp - bonus)
			member.hp = min(member.hp, member.max_hp)
		elif mat.passive_stat == "mp":
			var bonus: int = int(member.max_mp * mat.passive_pct / (1.0 + mat.passive_pct))
			member.max_mp = max(0, member.max_mp - bonus)
			member.mp = min(member.mp, member.max_mp)

func has_enemy_skill_materia(member_idx: int) -> bool:
	if member_idx < 0 or member_idx >= equipment.size():
		return false
	for slot_name in ["weapon", "armor"]:
		var item = equipment[member_idx].get(slot_name)
		if item == null:
			continue
		var slots: int = item.materia_slots if "materia_slots" in item else 0
		for s in range(slots):
			var mkey: String = "%d_%s_%d" % [member_idx, slot_name, s]
			var mat_path: String = materia_equipped.get(mkey, "")
			if mat_path == "":
				continue
			var mat = load(mat_path)
			if mat != null and mat.materia_type == "enemy_skill":
				return true
	return false

func learn_enemy_skill(spell_path: String) -> bool:
	if spell_path in learned_enemy_skills:
		return false
	learned_enemy_skills.append(spell_path)
	return true

func craft(recipe_idx: int) -> bool:
	if recipe_idx < 0 or recipe_idx >= CRAFT_RECIPES.size():
		return false
	var recipe: Dictionary = CRAFT_RECIPES[recipe_idx]
	for ing_path in recipe.ingredients:
		var needed: int = recipe.ingredients[ing_path]
		if inventory.get(ing_path, 0) < needed:
			return false
	for ing_path in recipe.ingredients:
		inventory[ing_path] = inventory.get(ing_path, 0) - recipe.ingredients[ing_path]
		if inventory[ing_path] <= 0:
			inventory.erase(ing_path)
	var result_path: String = recipe.result
	if recipe.result_type == "equip":
		equip_inventory[result_path] = equip_inventory.get(result_path, 0) + 1
	else:
		var item = load(result_path)
		if item != null:
			add_item(item)
	return true

func get_discounted_price(price: int) -> int:
	return int(price * merchant_discount)

func get_soldier_rank() -> String:
	if total_kills >= 150:
		return "1st Class"
	if total_kills >= 50:
		return "2nd Class"
	return "3rd Class"

func get_rank_xp_mult() -> float:
	if total_kills >= 50:
		return 1.10
	return 1.0

func get_rank_atk_mult() -> float:
	if total_kills >= 150:
		return 1.15
	return 1.0

func buy_item(item: Resource) -> bool:
	var cost: int = get_discounted_price(item.price)
	if gold < cost:
		return false
	var key: String = item.resource_path
	if inventory.get(key, 0) >= item.max_stack:
		return false
	gold -= cost
	gold_changed.emit(gold)
	add_item(item)
	return true

func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)

func grant_battle_rewards() -> void:
	var total_xp: int = 0
	var total_gold: int = 0
	for e in BattleManager.enemies:
		total_xp += e.xp_reward
		total_gold += e.gold_reward
	var is_named_boss: bool = BattleManager.is_boss1_battle or BattleManager.is_boss2_battle
	if is_named_boss:
		total_xp *= 3
		total_gold += 500
	if ng_plus_mode:
		total_xp = int(total_xp * 1.5)
		total_gold = int(total_gold * 1.5)
	add_gold(total_gold)
	var xp_mult: float = get_rank_xp_mult()
	var xp_with_bonus: int = int(total_xp * xp_mult)
	var any_levelup := false
	for m in alive_party():
		if m.add_xp(xp_with_bonus):
			any_levelup = true
	if any_levelup:
		AudioManager.play_sfx_levelup()
		var max_level: int = 0
		for m in party:
			if m.level > max_level:
				max_level = m.level
		level_up.emit(max_level)
	BattleManager.last_xp = xp_with_bonus
	BattleManager.last_gold = total_gold
	# Restore 20% MP to all party members after victory
	for m in party:
		if m.max_mp > 0:
			m.mp = min(m.max_mp, m.mp + int(m.max_mp * 0.20))

func show_wall_market() -> void:
	wall_market_visits += 1
	_check_wall_market_unlock()
	var canvas := CanvasLayer.new()
	canvas.layer = 92
	get_tree().root.add_child(canvas)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -320.0
	panel.offset_top = -420.0
	panel.offset_right = 320.0
	panel.offset_bottom = 420.0
	canvas.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)
	var title := Label.new()
	title.text = "🏪 Wall Market"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	var gold_lbl := Label.new()
	gold_lbl.text = "Or : %d G" % gold
	gold_lbl.add_theme_font_size_override("font_size", 24)
	gold_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.4, 1.0))
	vbox.add_child(gold_lbl)
	if wall_market_visits <= 1 or randf() < 0.30:
		var louche_lbl := Label.new()
		louche_lbl.text = "🤫 Affaire Louche disponible !"
		louche_lbl.add_theme_font_size_override("font_size", 22)
		louche_lbl.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5, 1.0))
		vbox.add_child(louche_lbl)
		var louche_btn := Button.new()
		louche_btn.text = "Accepter (100 G)"
		louche_btn.add_theme_font_size_override("font_size", 22)
		louche_btn.pressed.connect(_on_louche_accepted.bind(louche_btn, gold_lbl))
		vbox.add_child(louche_btn)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 200)
	vbox.add_child(scroll)
	var items_vbox := VBoxContainer.new()
	scroll.add_child(items_vbox)
	var shop_items: Array = WALL_MARKET_ITEMS.duplicate()
	if wall_market_visits >= 5:
		shop_items.append({"path": WALL_MARKET_UNLOCK_ITEM, "price": 3000, "type": "equip"})
	for entry in shop_items:
		var res = load(entry.path)
		if res == null:
			continue
		var name_str: String = res.item_name if entry.type == "item" else res.equip_name
		var row := HBoxContainer.new()
		var item_lbl := Label.new()
		item_lbl.text = "%s — %d G" % [name_str, entry.price]
		item_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item_lbl.add_theme_font_size_override("font_size", 20)
		row.add_child(item_lbl)
		var buy_btn := Button.new()
		buy_btn.text = "Acheter"
		buy_btn.add_theme_font_size_override("font_size", 20)
		buy_btn.pressed.connect(_on_wall_market_buy.bind(entry, gold_lbl, buy_btn))
		row.add_child(buy_btn)
		items_vbox.add_child(row)
	var close_btn := Button.new()
	close_btn.text = "Fermer"
	close_btn.add_theme_font_size_override("font_size", 26)
	close_btn.pressed.connect(canvas.queue_free)
	vbox.add_child(close_btn)

func _check_wall_market_unlock() -> void:
	if wall_market_visits == 5:
		var file_id: String = "wall_market_unlock"
		if not file_id in shinra_files_seen:
			shinra_files_seen.append(file_id)
			_show_shinra_popup("🏪 Wall Market — Débloqué !", "Un mystérieux marchand du Wall Market propose désormais la Black Materia Shard...")

func _on_louche_accepted(btn: Button, gold_lbl: Label) -> void:
	if gold < 100:
		btn.text = "Pas assez d'or !"
		return
	gold -= 100
	gold_lbl.text = "Or : %d G" % gold
	btn.disabled = true
	if randf() < 0.5:
		var idx: int = randi() % WALL_MARKET_DEAL_ITEMS.size()
		var item = load(WALL_MARKET_DEAL_ITEMS[idx])
		if item != null:
			add_item(item)
			btn.text = "✅ Bonne affaire ! +%s" % item.item_name
		else:
			btn.text = "✅ Bonne affaire !"
	else:
		btn.text = "❌ Arnaqué ! -100 G"

func _on_wall_market_buy(entry: Dictionary, gold_lbl: Label, btn: Button) -> void:
	if gold < entry.price:
		btn.text = "Pas assez d'or !"
		return
	gold -= entry.price
	gold_lbl.text = "Or : %d G" % gold
	if entry.type == "item":
		var item = load(entry.path)
		if item != null:
			add_item(item)
	else:
		equip_inventory[entry.path] = equip_inventory.get(entry.path, 0) + 1

const FORGE_BASE_COST: int = 200
const FORGE_MAX_LEVEL: int = 3
const FORGE_STAT_PER_LEVEL: int = 5

func get_upgrade_level(path: String) -> int:
	return int(equip_inventory.get(path + "_upgrades", 0))

func set_upgrade_level(path: String, lvl: int) -> void:
	var key: String = path + "_upgrades"
	if lvl <= 0:
		equip_inventory.erase(key)
	else:
		equip_inventory[key] = lvl

func show_forge_popup() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 93
	get_tree().root.add_child(layer)
	var panel: Panel = Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	panel.offset_left = -260
	panel.offset_right = 260
	panel.offset_top = -300
	panel.offset_bottom = 300
	layer.add_child(panel)
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 12
	vbox.offset_right = -12
	vbox.offset_top = 12
	vbox.offset_bottom = -12
	panel.add_child(vbox)
	var title: Label = Label.new()
	title.text = "🔨 Forge d'Armes"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	var gold_lbl: Label = Label.new()
	gold_lbl.text = "Or : %d G" % gold
	gold_lbl.add_theme_font_size_override("font_size", 24)
	gold_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0, 1))
	gold_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(gold_lbl)
	var slot_names: Array = ["weapon", "armor"]
	for p_idx in min(party.size(), equipment.size()):
		var member = party[p_idx]
		for slot_name in slot_names:
			var item = equipment[p_idx].get(slot_name)
			if item == null:
				continue
			var upgrade_lvl: int = get_upgrade_level(item.resource_path)
			var cost: int = FORGE_BASE_COST * (upgrade_lvl + 1)
			var row: HBoxContainer = HBoxContainer.new()
			vbox.add_child(row)
			var info: Label = Label.new()
			info.text = "%s [%s] +%d (Lv%d)" % [member.unit_name, item.equip_name, item.stat_bonus, upgrade_lvl]
			info.add_theme_font_size_override("font_size", 20)
			info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(info)
			var forge_btn: Button = Button.new()
			if upgrade_lvl >= FORGE_MAX_LEVEL:
				forge_btn.text = "MAX"
				forge_btn.disabled = true
			else:
				forge_btn.text = "+5 (%dG)" % cost
			forge_btn.add_theme_font_size_override("font_size", 20)
			forge_btn.pressed.connect(_on_forge_upgrade.bind(p_idx, slot_name, forge_btn, info, gold_lbl))
			row.add_child(forge_btn)
	var close_btn: Button = Button.new()
	close_btn.text = "Fermer"
	close_btn.add_theme_font_size_override("font_size", 26)
	close_btn.pressed.connect(func() -> void: layer.queue_free())
	vbox.add_child(close_btn)

func _on_forge_upgrade(p_idx: int, slot_name: String, btn: Button, info_lbl: Label, gold_lbl: Label) -> void:
	if p_idx >= party.size() or p_idx >= equipment.size():
		return
	var member = party[p_idx]
	var item = equipment[p_idx].get(slot_name)
	if item == null:
		return
	var upgrade_lvl: int = get_upgrade_level(item.resource_path)
	if upgrade_lvl >= FORGE_MAX_LEVEL:
		return
	var cost: int = FORGE_BASE_COST * (upgrade_lvl + 1)
	if gold < cost:
		btn.text = "Pas assez d'or !"
		return
	gold -= cost
	gold_lbl.text = "Or : %d G" % gold
	gold_changed.emit(gold)
	item.stat_bonus += FORGE_STAT_PER_LEVEL
	if item.slot == 0:
		member.atk += FORGE_STAT_PER_LEVEL
	else:
		member.def += FORGE_STAT_PER_LEVEL
	upgrade_lvl += 1
	set_upgrade_level(item.resource_path, upgrade_lvl)
	info_lbl.text = "%s [%s] +%d (Lv%d)" % [member.unit_name, item.equip_name, item.stat_bonus, upgrade_lvl]
	if upgrade_lvl >= FORGE_MAX_LEVEL:
		btn.text = "MAX"
		btn.disabled = true
	else:
		var next_cost: int = FORGE_BASE_COST * (upgrade_lvl + 1)
		btn.text = "+5 (%dG)" % next_cost

const BOSS_RUSH_SEQUENCE: Array = [
	{"name": "Guard Scorpion", "path": "res://resources/units/guard_scorpion.tres"},
	{"name": "Jenova",         "path": "res://resources/units/jenova.tres"},
	{"name": "Dark Knight",    "path": "res://resources/units/dark_knight.tres"},
	{"name": "Ruby Weapon",    "path": "res://resources/units/ruby_weapon.tres"},
	{"name": "Emerald Weapon", "path": "res://resources/units/emerald_weapon.tres"},
]

var _boss_rush_current: int = 0
var _boss_rush_canvas: CanvasLayer = null

func start_boss_rush() -> void:
	if not sephiroth_defeated:
		return
	boss_rush_active = true
	_boss_rush_current = 0
	_boss_rush_canvas = null
	_boss_rush_next_fight()

func _boss_rush_next_fight() -> void:
	if _boss_rush_current >= BOSS_RUSH_SEQUENCE.size():
		_on_boss_rush_complete()
		return
	var entry: Dictionary = BOSS_RUSH_SEQUENCE[_boss_rush_current]
	var canvas: CanvasLayer = CanvasLayer.new()
	canvas.layer = 95
	get_tree().root.add_child(canvas)
	_boss_rush_canvas = canvas
	var lbl: Label = Label.new()
	lbl.text = "⚔️ Boss Rush — Combat %d/5\nProchain : %s" % [_boss_rush_current + 1, entry.name]
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.1, 1))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	lbl.offset_left = -300
	lbl.offset_right = 300
	lbl.offset_top = -60
	lbl.offset_bottom = 60
	canvas.add_child(lbl)
	var btn: Button = Button.new()
	btn.text = "Combattre !"
	btn.add_theme_font_size_override("font_size", 28)
	btn.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	btn.offset_left = -120
	btn.offset_right = 120
	btn.offset_top = 80
	btn.offset_bottom = 140
	btn.pressed.connect(_on_boss_rush_fight.bind(entry, canvas))
	canvas.add_child(btn)

func _on_boss_rush_fight(entry: Dictionary, canvas: CanvasLayer) -> void:
	canvas.queue_free()
	var enemy_res = load(entry.path)
	if enemy_res == null:
		_boss_rush_current += 1
		_boss_rush_next_fight()
		return
	BattleManager.enemies.clear()
	BattleManager.enemies.append(enemy_res.duplicate())
	BattleManager.party = party
	BattleManager.is_boss_battle = true
	BattleManager.battle_ended.connect(_on_boss_rush_battle_ended, CONNECT_ONE_SHOT)
	get_tree().change_scene_to_file("res://scenes/combat/Battle.tscn")

func _on_boss_rush_battle_ended(result) -> void:
	if result == "win" or result == true:
		_boss_rush_current += 1
		if _boss_rush_current > boss_rush_best_score:
			boss_rush_best_score = _boss_rush_current
		if _boss_rush_current >= BOSS_RUSH_SEQUENCE.size():
			_on_boss_rush_complete()
		else:
			get_tree().change_scene_to_file("res://scenes/world/WorldMap.tscn")
	else:
		boss_rush_active = false
		if _boss_rush_current > boss_rush_best_score:
			boss_rush_best_score = _boss_rush_current
		get_tree().change_scene_to_file("res://scenes/world/WorldMap.tscn")

func _on_boss_rush_complete() -> void:
	boss_rush_active = false
	boss_rush_best_score = BOSS_RUSH_SEQUENCE.size()
	var hero_drink = load("res://resources/items/hero_drink.tres")
	for i in 3:
		if hero_drink != null:
			add_item(hero_drink)
	_show_shinra_popup("🏆 Champion du Boss Rush !", "Tu as vaincu les 5 boss en séquence. Légendaire !")

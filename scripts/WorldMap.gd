extends Node2D

const MAP_WIDTH := 3200.0
const MAP_HEIGHT := 3200.0
const CAMERA_LERP := 5.0

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D
@onready var joystick: Control = $VirtualJoystick
@onready var _pause_menu = $PauseMenu

const RANDOM_EVENT_CHANCE := 0.1

var _shop_scene: PackedScene = preload("res://scenes/ui/Shop.tscn")
var _event_popup_scene: PackedScene = preload("res://scenes/ui/EventPopup.tscn")
var _shop_open: bool = false
var _inn_dialog = null
var _quest_open: bool = false
var _weather_layer = null
var _party_menu_open: bool = false
var _party_menu_canvas = null
var _party_checkboxes: Array = []

func _ready() -> void:
	GameManager.set_state(GameManager.GameState.WORLD)
	AudioManager.play_zone_bgm(GameManager.active_zone)
	_update_weather(GameManager.active_zone)
	player.encounter_triggered.connect(_on_encounter)
	joystick.input_vector.connect(player.set_joystick_input)
	$DungeonEntrance.body_entered.connect(_on_dungeon_entrance)
	$ShopNPC.body_entered.connect(_on_shop_entered)
	$InnNPC.body_entered.connect(_on_inn_entered)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = CAMERA_LERP
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(MAP_WIDTH)
	camera.limit_bottom = int(MAP_HEIGHT)
	camera.global_position = player.global_position
	$PauseLayer/PauseButton.pressed.connect(_pause_menu.show_pause)
	_add_zone_buttons()
	_add_boss_buttons()
	_add_weapon_buttons()
	_add_sector_buttons()
	_add_arena_button()
	_add_party_button()
	_add_npc_buttons()
	_add_quest_button()
	_add_bestiary_button()
	_add_wall_market_button()
	if GameManager.pending_rank_notification != "":
		var rn: String = GameManager.pending_rank_notification
		GameManager.pending_rank_notification = ""
		_show_inn_feedback("Rang atteint : %s SOLDIER !" % rn)
	GameManager.check_shinra_files()
	if not GameManager.story_intro_done:
		GameManager.story_intro_done = true
		DialogueManager.show_prologue(self)

func _add_npc_buttons() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 6
	add_child(layer)
	var npcs := [
		{"id": "npc_guide",     "label": "💬 Guide",      "x": 220.0, "top": -300.0, "bot": -210.0},
		{"id": "npc_soldier",   "label": "💬 Soldat",     "x": 220.0, "top": -205.0, "bot": -115.0},
		{"id": "npc_innkeeper", "label": "💬 Aubergiste", "x": 220.0, "top": -110.0, "bot": -20.0},
	]
	for z in npcs:
		var btn := Button.new()
		btn.text = z.label
		btn.add_theme_font_size_override("font_size", 22)
		btn.custom_minimum_size = Vector2(170, 80)
		btn.anchor_left = 0.5
		btn.anchor_right = 0.5
		btn.anchor_top = 1.0
		btn.anchor_bottom = 1.0
		btn.offset_left = -85.0
		btn.offset_right = 85.0
		btn.offset_top = z.top
		btn.offset_bottom = z.bot
		btn.pressed.connect(func(): GameManager.show_npc_choice(z.id))
		layer.add_child(btn)

func _add_quest_button() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 7
	add_child(layer)
	var btn := Button.new()
	btn.text = "📜 Quêtes"
	btn.add_theme_font_size_override("font_size", 26)
	btn.custom_minimum_size = Vector2(180, 70)
	btn.anchor_left = 0.5
	btn.anchor_right = 0.5
	btn.anchor_top = 0.0
	btn.anchor_bottom = 0.0
	btn.offset_left = -90.0
	btn.offset_right = 90.0
	btn.offset_top = 10.0
	btn.offset_bottom = 80.0
	btn.pressed.connect(_on_quest_pressed)
	layer.add_child(btn)

func _on_quest_pressed() -> void:
	if _quest_open:
		return
	_quest_open = true
	var menu := load("res://scenes/ui/QuestMenu.tscn").instantiate()
	add_child(menu)
	menu.closed.connect(func(): _quest_open = false)

func _add_wall_market_button() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 8
	add_child(layer)
	var btn := Button.new()
	btn.text = "🏪 Wall Market"
	btn.add_theme_font_size_override("font_size", 26)
	btn.custom_minimum_size = Vector2(200, 70)
	btn.anchor_left = 0.5
	btn.anchor_right = 0.5
	btn.anchor_top = 0.0
	btn.anchor_bottom = 0.0
	btn.offset_left = -310.0
	btn.offset_right = -110.0
	btn.offset_top = 10.0
	btn.offset_bottom = 80.0
	btn.pressed.connect(func() -> void: GameManager.show_wall_market())
	layer.add_child(btn)

func _add_bestiary_button() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 8
	add_child(layer)
	var btn := Button.new()
	btn.text = "📖 Bestiaire"
	btn.add_theme_font_size_override("font_size", 26)
	btn.custom_minimum_size = Vector2(190, 70)
	btn.anchor_left = 0.5
	btn.anchor_right = 0.5
	btn.anchor_top = 0.0
	btn.anchor_bottom = 0.0
	btn.offset_left = 110.0
	btn.offset_right = 300.0
	btn.offset_top = 10.0
	btn.offset_bottom = 80.0
	btn.pressed.connect(_on_bestiary_pressed)
	layer.add_child(btn)

func _on_bestiary_pressed() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 92
	add_child(canvas)
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.75)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(bg)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 40.0
	scroll.offset_right = -40.0
	scroll.offset_top = 60.0
	scroll.offset_bottom = -60.0
	canvas.add_child(scroll)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)
	var title := Label.new()
	title.text = "📖 Bestiaire"
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4, 1))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	var all_enemies: Array = GameManager.BESTIARY.keys()
	all_enemies.sort()
	for en in all_enemies:
		var kills: int = QuestManager.kill_counts.get(en, 0)
		var entry: Dictionary = GameManager.BESTIARY[en]
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 2)
		var row_bg := PanelContainer.new()
		var inner := VBoxContainer.new()
		inner.add_theme_constant_override("separation", 4)
		var name_lbl := Label.new()
		name_lbl.add_theme_font_size_override("font_size", 28)
		if kills == 0:
			name_lbl.text = "??? (non rencontré)"
			name_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
			inner.add_child(name_lbl)
		else:
			name_lbl.text = "%s  [%d kills]" % [en, kills]
			name_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4, 1))
			var stats_lbl := Label.new()
			stats_lbl.text = "HP: %d  ATK: %d" % [entry.base_hp, entry.base_atk]
			stats_lbl.add_theme_font_size_override("font_size", 22)
			stats_lbl.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0, 1))
			var lore_lbl := Label.new()
			lore_lbl.text = entry.lore
			lore_lbl.add_theme_font_size_override("font_size", 20)
			lore_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 1))
			lore_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			var milestone: int = entry.get("milestone", 10)
			var given: bool = GameManager.bestiary_milestones_given.get(en, false)
			var milestone_lbl := Label.new()
			if given:
				milestone_lbl.text = "★ Récompense %d kills obtenue !" % milestone
				milestone_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5, 1))
			else:
				milestone_lbl.text = "Récompense à %d kills (%d/%d)" % [milestone, kills, milestone]
				milestone_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
			milestone_lbl.add_theme_font_size_override("font_size", 20)
			inner.add_child(name_lbl)
			inner.add_child(stats_lbl)
			inner.add_child(lore_lbl)
			inner.add_child(milestone_lbl)
		row_bg.add_child(inner)
		vbox.add_child(row_bg)
	var close_btn := Button.new()
	close_btn.text = "Fermer"
	close_btn.add_theme_font_size_override("font_size", 30)
	close_btn.custom_minimum_size = Vector2(200, 70)
	close_btn.pressed.connect(canvas.queue_free)
	var close_row := HBoxContainer.new()
	close_row.alignment = BoxContainer.ALIGNMENT_CENTER
	close_row.add_child(close_btn)
	vbox.add_child(close_row)

func _add_zone_buttons() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 4
	add_child(layer)
	var zones := [
		{"id": "midgar",   "label": "🏙 Midgar\n(Lv.1+)",  "req": 1,  "color": Color(0.9, 0.7, 0.2, 1)},
		{"id": "kalm",     "label": "🌿 Kalm\n(Lv.5+)",    "req": 5,  "color": Color(0.3, 0.8, 0.3, 1)},
		{"id": "mt_nibel", "label": "🏔 Mt.Nibel\n(Lv.10+)", "req": 10, "color": Color(0.6, 0.4, 0.9, 1)},
	]
	for i in zones.size():
		var z: Dictionary = zones[i]
		var btn := Button.new()
		btn.text = z.label
		btn.add_theme_font_size_override("font_size", 22)
		btn.custom_minimum_size = Vector2(170, 90)
		btn.anchor_right = 1.0
		btn.anchor_top = 0.0
		btn.anchor_left = 1.0
		btn.anchor_bottom = 0.0
		btn.offset_left = -185.0
		btn.offset_right = -10.0
		btn.offset_top = 10.0 + i * 100.0
		btn.offset_bottom = 100.0 + i * 100.0
		btn.pressed.connect(_on_zone_pressed.bind(z.id, z.req))
		layer.add_child(btn)

func _on_zone_pressed(zone_id: String, req_level: int) -> void:
	var avg_level: int = 0
	for m in GameManager.party:
		avg_level += m.level
	avg_level = avg_level / max(1, GameManager.party.size())
	if avg_level < req_level:
		_show_level_required(req_level)
		return
	GameManager.active_zone = zone_id
	AudioManager.play_zone_bgm(zone_id)
	_update_weather(zone_id)
	_show_zone_activated(zone_id)

func _show_zone_activated(zone_id: String) -> void:
	var names := {"midgar": "Midgar", "kalm": "Kalm", "mt_nibel": "Mt. Nibel"}
	var layer := CanvasLayer.new()
	layer.layer = 98
	add_child(layer)
	var lbl := Label.new()
	lbl.text = "Zone active : %s" % names.get(zone_id, zone_id)
	lbl.add_theme_font_size_override("font_size", 38)
	lbl.add_theme_color_override("font_color", Color(0.2, 0.9, 0.4, 1))
	lbl.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	layer.add_child(lbl)
	await get_tree().create_timer(2.0).timeout
	layer.queue_free()

func _update_weather(zone_name: String) -> void:
	if _weather_layer != null:
		_weather_layer.queue_free()
	_weather_layer = CanvasLayer.new()
	_weather_layer.layer = 2
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	match zone_name:
		"midgar":
			rect.color = Color(0.5, 0.5, 0.5, 0.15)
			_weather_layer.add_child(rect)
			add_child(_weather_layer)
			var tw := create_tween()
			tw.set_loops()
			tw.tween_property(rect, "color:a", 0.05, 1.5)
			tw.tween_property(rect, "color:a", 0.15, 1.5)
		"kalm":
			rect.color = Color(0.6, 0.8, 1.0, 0.08)
			_weather_layer.add_child(rect)
			add_child(_weather_layer)
		"mt_nibel":
			rect.color = Color(1.0, 1.0, 1.0, 0.10)
			_weather_layer.add_child(rect)
			add_child(_weather_layer)
			var tw := create_tween()
			tw.set_loops()
			tw.tween_property(rect, "color:a", 0.03, 2.0)
			tw.tween_property(rect, "color:a", 0.10, 2.0)
		_:
			rect.color = Color(0.5, 0.5, 0.5, 0.12)
			_weather_layer.add_child(rect)
			add_child(_weather_layer)

func _add_boss_buttons() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	var seph_btn := Button.new()
	seph_btn.text = "★ Sephiroth\n[Boss Final] (Lv.15+)"
	seph_btn.add_theme_font_size_override("font_size", 22)
	seph_btn.add_theme_color_override("font_color", Color(0.85, 0.85, 1.0, 1))
	seph_btn.custom_minimum_size = Vector2(200, 90)
	seph_btn.anchor_left = 0.0
	seph_btn.anchor_top = 1.0
	seph_btn.anchor_right = 0.0
	seph_btn.anchor_bottom = 1.0
	seph_btn.offset_left = 10.0
	seph_btn.offset_top = -290.0
	seph_btn.offset_right = 215.0
	seph_btn.offset_bottom = -195.0
	seph_btn.pressed.connect(_on_sephiroth_pressed)
	layer.add_child(seph_btn)
	var boss1_btn := Button.new()
	boss1_btn.text = "⚔ Guard Scorpion\n[Boss 1] (Lv.5+)"
	boss1_btn.add_theme_font_size_override("font_size", 22)
	boss1_btn.custom_minimum_size = Vector2(200, 90)
	boss1_btn.anchor_left = 0.0
	boss1_btn.anchor_top = 1.0
	boss1_btn.anchor_right = 0.0
	boss1_btn.anchor_bottom = 1.0
	boss1_btn.offset_left = 10.0
	boss1_btn.offset_top = -195.0
	boss1_btn.offset_right = 215.0
	boss1_btn.offset_bottom = -100.0
	boss1_btn.pressed.connect(_on_boss1_pressed)
	layer.add_child(boss1_btn)
	var boss2_btn := Button.new()
	boss2_btn.text = "⚔ Jenova\n[Boss 2] (Lv.10+)"
	boss2_btn.add_theme_font_size_override("font_size", 22)
	boss2_btn.custom_minimum_size = Vector2(200, 90)
	boss2_btn.anchor_left = 0.0
	boss2_btn.anchor_top = 1.0
	boss2_btn.anchor_right = 0.0
	boss2_btn.anchor_bottom = 1.0
	boss2_btn.offset_left = 10.0
	boss2_btn.offset_top = -100.0
	boss2_btn.offset_right = 215.0
	boss2_btn.offset_bottom = -5.0
	boss2_btn.pressed.connect(_on_boss2_pressed)
	layer.add_child(boss2_btn)

func _add_sector_buttons() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 4
	add_child(layer)
	var sectors := [
		{"id": "sector1", "label": "🏭 Secteur 1\nRéacteur", "color": Color(0.2, 0.5, 1.0, 1)},
		{"id": "sector5", "label": "🏚 Secteur 5\nSlums",    "color": Color(0.7, 0.5, 0.2, 1)},
		{"id": "sector7", "label": "🍺 Secteur 7\n7th Heaven","color": Color(0.3, 0.8, 0.4, 1)},
	]
	for i in sectors.size():
		var s: Dictionary = sectors[i]
		var btn := Button.new()
		btn.text = s.label
		btn.add_theme_font_size_override("font_size", 20)
		btn.add_theme_color_override("font_color", s.color)
		btn.custom_minimum_size = Vector2(160, 80)
		btn.anchor_left = 0.5
		btn.anchor_right = 0.5
		btn.anchor_top = 0.0
		btn.anchor_bottom = 0.0
		btn.offset_left = -240.0 + i * 170.0
		btn.offset_right = -75.0 + i * 170.0
		btn.offset_top = 10.0
		btn.offset_bottom = 95.0
		btn.pressed.connect(_on_sector_pressed.bind(s.id))
		layer.add_child(btn)

func _on_sector_pressed(sector: String) -> void:
	GameManager.return_after_battle = "res://scenes/world/WorldMap.tscn"
	BattleManager.sector_mode = sector
	BattleManager.is_boss_battle = false
	BattleManager.is_boss1_battle = false
	BattleManager.is_boss2_battle = false
	BattleManager.is_boss_sephiroth_battle = false
	BattleManager.is_ruby_weapon_battle = false
	BattleManager.is_emerald_weapon_battle = false
	BattleManager.arena_mode = false
	BattleManager.dungeon_mode = false
	GameManager.change_scene("res://scenes/combat/Battle.tscn")

func _add_weapon_buttons() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	var ruby_btn := Button.new()
	ruby_btn.text = "⚔ Ruby Weapon\n[Lv.20+]"
	ruby_btn.add_theme_font_size_override("font_size", 22)
	ruby_btn.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2, 1))
	ruby_btn.custom_minimum_size = Vector2(200, 90)
	ruby_btn.anchor_left = 0.0
	ruby_btn.anchor_top = 1.0
	ruby_btn.anchor_right = 0.0
	ruby_btn.anchor_bottom = 1.0
	ruby_btn.offset_left = 10.0
	ruby_btn.offset_top = -490.0
	ruby_btn.offset_right = 215.0
	ruby_btn.offset_bottom = -395.0
	ruby_btn.pressed.connect(_on_ruby_weapon_pressed)
	layer.add_child(ruby_btn)
	var emerald_btn := Button.new()
	emerald_btn.text = "⚔ Emerald Weapon\n[Lv.20+]"
	emerald_btn.add_theme_font_size_override("font_size", 22)
	emerald_btn.add_theme_color_override("font_color", Color(0.2, 0.9, 0.35, 1))
	emerald_btn.custom_minimum_size = Vector2(200, 90)
	emerald_btn.anchor_left = 0.0
	emerald_btn.anchor_top = 1.0
	emerald_btn.anchor_right = 0.0
	emerald_btn.anchor_bottom = 1.0
	emerald_btn.offset_left = 10.0
	emerald_btn.offset_top = -390.0
	emerald_btn.offset_right = 215.0
	emerald_btn.offset_bottom = -295.0
	emerald_btn.pressed.connect(_on_emerald_weapon_pressed)
	layer.add_child(emerald_btn)

func _on_ruby_weapon_pressed() -> void:
	var avg_level: int = 0
	for m in GameManager.party:
		avg_level += m.level
	avg_level = avg_level / max(1, GameManager.party.size())
	if avg_level < 20:
		_show_level_required(20)
		return
	GameManager.return_after_battle = "res://scenes/world/WorldMap.tscn"
	BattleManager.is_ruby_weapon_battle = true
	BattleManager.is_emerald_weapon_battle = false
	BattleManager.is_boss_battle = false
	BattleManager.is_boss1_battle = false
	BattleManager.is_boss2_battle = false
	BattleManager.is_boss_sephiroth_battle = false
	BattleManager.dungeon_mode = false
	GameManager.change_scene("res://scenes/combat/Battle.tscn")

func _on_emerald_weapon_pressed() -> void:
	var avg_level: int = 0
	for m in GameManager.party:
		avg_level += m.level
	avg_level = avg_level / max(1, GameManager.party.size())
	if avg_level < 20:
		_show_level_required(20)
		return
	GameManager.return_after_battle = "res://scenes/world/WorldMap.tscn"
	BattleManager.is_emerald_weapon_battle = true
	BattleManager.is_ruby_weapon_battle = false
	BattleManager.is_boss_battle = false
	BattleManager.is_boss1_battle = false
	BattleManager.is_boss2_battle = false
	BattleManager.is_boss_sephiroth_battle = false
	BattleManager.dungeon_mode = false
	GameManager.change_scene("res://scenes/combat/Battle.tscn")

func _on_sephiroth_pressed() -> void:
	var avg_level: int = 0
	for m in GameManager.party:
		avg_level += m.level
	avg_level = avg_level / max(1, GameManager.party.size())
	if avg_level < 15:
		_show_level_required(15)
		return
	GameManager.return_after_battle = "res://scenes/world/WorldMap.tscn"
	BattleManager.is_boss_sephiroth_battle = true
	BattleManager.is_boss1_battle = false
	BattleManager.is_boss2_battle = false
	BattleManager.dungeon_mode = false
	GameManager.change_scene("res://scenes/combat/Battle.tscn")

func _on_boss1_pressed() -> void:
	var avg_level: int = 0
	for m in GameManager.party:
		avg_level += m.level
	avg_level = avg_level / max(1, GameManager.party.size())
	if avg_level < 5:
		_show_level_required(5)
		return
	GameManager.return_after_battle = "res://scenes/world/WorldMap.tscn"
	BattleManager.is_boss1_battle = true
	BattleManager.is_boss2_battle = false
	BattleManager.is_boss_sephiroth_battle = false
	BattleManager.dungeon_mode = false
	GameManager.change_scene("res://scenes/combat/Battle.tscn")

func _on_boss2_pressed() -> void:
	var avg_level: int = 0
	for m in GameManager.party:
		avg_level += m.level
	avg_level = avg_level / max(1, GameManager.party.size())
	if avg_level < 10:
		_show_level_required(10)
		return
	GameManager.return_after_battle = "res://scenes/world/WorldMap.tscn"
	BattleManager.is_boss1_battle = false
	BattleManager.is_boss2_battle = true
	BattleManager.is_boss_sephiroth_battle = false
	BattleManager.dungeon_mode = false
	GameManager.change_scene("res://scenes/combat/Battle.tscn")

func _add_arena_button() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	var btn := Button.new()
	btn.text = "⚔ Arène\n[8 vagues] (Lv.10+)"
	btn.add_theme_font_size_override("font_size", 22)
	btn.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1))
	btn.custom_minimum_size = Vector2(200, 90)
	btn.anchor_left = 1.0
	btn.anchor_top = 0.0
	btn.anchor_right = 1.0
	btn.anchor_bottom = 0.0
	btn.offset_left = -215.0
	btn.offset_top = 10.0
	btn.offset_right = -10.0
	btn.offset_bottom = 105.0
	btn.pressed.connect(_on_arena_pressed)
	layer.add_child(btn)

func _add_party_button() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	var btn := Button.new()
	btn.text = "Party\n[Équipe]"
	btn.add_theme_font_size_override("font_size", 22)
	btn.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6, 1))
	btn.custom_minimum_size = Vector2(160, 90)
	btn.anchor_left = 1.0
	btn.anchor_top = 0.0
	btn.anchor_right = 1.0
	btn.anchor_bottom = 0.0
	btn.offset_left = -215.0
	btn.offset_top = 120.0
	btn.offset_right = -10.0
	btn.offset_bottom = 215.0
	btn.pressed.connect(_on_party_pressed)
	layer.add_child(btn)

func _on_party_pressed() -> void:
	if _party_menu_open:
		return
	_party_menu_open = true
	var canvas := CanvasLayer.new()
	canvas.layer = 50
	_party_menu_canvas = canvas
	add_child(canvas)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -260
	panel.offset_right = 260
	panel.offset_top = -240
	panel.offset_bottom = 240
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	var title := Label.new()
	title.text = "Sélectionner 3 membres"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	vbox.add_child(title)
	_party_checkboxes = []
	for i in GameManager.available_members.size():
		var m = GameManager.available_members[i]
		var cb := CheckBox.new()
		cb.text = "%s (%s) Lv.%d" % [m.unit_name, m.character_class, m.level]
		cb.add_theme_font_size_override("font_size", 26)
		cb.button_pressed = i in GameManager.active_party_indices
		_party_checkboxes.append(cb)
		vbox.add_child(cb)
	var ok_btn := Button.new()
	ok_btn.text = "Confirmer (3 membres)"
	ok_btn.add_theme_font_size_override("font_size", 26)
	ok_btn.custom_minimum_size = Vector2(0, 70)
	ok_btn.pressed.connect(_on_party_confirm)
	vbox.add_child(ok_btn)
	var cancel_btn := Button.new()
	cancel_btn.text = "Annuler"
	cancel_btn.add_theme_font_size_override("font_size", 26)
	cancel_btn.pressed.connect(_on_party_cancel)
	vbox.add_child(cancel_btn)
	panel.add_child(vbox)
	canvas.add_child(panel)

func _on_party_confirm() -> void:
	var indices: Array = []
	for i in _party_checkboxes.size():
		if _party_checkboxes[i].button_pressed:
			indices.append(i)
	if indices.size() != 3:
		return
	GameManager.set_active_party_indices(indices)
	_on_party_cancel()

func _on_party_cancel() -> void:
	_party_menu_open = false
	_party_checkboxes = []
	if _party_menu_canvas != null:
		_party_menu_canvas.queue_free()
		_party_menu_canvas = null

func _on_arena_pressed() -> void:
	var avg_level: int = 0
	for m in GameManager.party:
		avg_level += m.level
	avg_level = avg_level / max(1, GameManager.party.size())
	if avg_level < 10:
		_show_level_required(10)
		return
	GameManager.return_after_battle = "res://scenes/world/WorldMap.tscn"
	BattleManager.is_boss_battle = false
	BattleManager.is_boss1_battle = false
	BattleManager.is_boss2_battle = false
	BattleManager.is_boss_sephiroth_battle = false
	BattleManager.dungeon_mode = false
	BattleManager.arena_mode = true
	GameManager.change_scene("res://scenes/combat/Battle.tscn")

func _show_level_required(req: int) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 99
	add_child(layer)
	var lbl := Label.new()
	lbl.text = "Niveau %d requis !" % req
	lbl.add_theme_font_size_override("font_size", 40)
	lbl.add_theme_color_override("font_color", Color(1, 0.3, 0.3, 1))
	lbl.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	layer.add_child(lbl)
	await get_tree().create_timer(2.0).timeout
	layer.queue_free()

func _process(_delta: float) -> void:
	camera.global_position = camera.global_position.lerp(player.global_position, CAMERA_LERP * get_process_delta_time())

func _on_shop_entered(body: Node) -> void:
	if body == player and not _shop_open:
		_shop_open = true
		var shop := _shop_scene.instantiate()
		shop.tree_exited.connect(func(): _shop_open = false)
		get_tree().root.add_child(shop)

func _on_dungeon_entrance(body: Node) -> void:
	if body == player:
		GameManager.change_scene("res://scenes/world/Dungeon.tscn")

func _on_inn_entered(body: Node) -> void:
	if body != player or _inn_dialog != null:
		return
	_show_inn_dialog()

func _show_inn_dialog() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 30
	_inn_dialog = canvas
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -300
	panel.offset_right = 300
	panel.offset_top = -200
	panel.offset_bottom = 200
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	var lbl := Label.new()
	lbl.text = "Welcome to the Inn!\nRest and recover all HP/MP?\nCost: 30 Gold"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 28)
	var yes_btn := Button.new()
	yes_btn.text = "Rest (30G)"
	yes_btn.add_theme_font_size_override("font_size", 30)
	yes_btn.custom_minimum_size = Vector2(0, 80)
	yes_btn.pressed.connect(_on_inn_yes)
	var no_btn := Button.new()
	no_btn.text = "No Thanks"
	no_btn.add_theme_font_size_override("font_size", 30)
	no_btn.custom_minimum_size = Vector2(0, 80)
	no_btn.pressed.connect(_on_inn_no)
	vbox.add_child(lbl)
	vbox.add_child(yes_btn)
	vbox.add_child(no_btn)
	panel.add_child(vbox)
	canvas.add_child(panel)
	add_child(canvas)

func _on_inn_yes() -> void:
	if GameManager.gold < 30:
		_show_inn_feedback("Not enough gold!")
		return
	GameManager.gold -= 30
	GameManager.gold_changed.emit(GameManager.gold)
	for m in GameManager.party:
		m.hp = m.max_hp
		m.mp = m.max_mp
		m.clear_status()
	SaveSystem.save(0)
	_close_inn_dialog()
	_show_inn_feedback("Rested well! Party fully recovered.")

func _on_inn_no() -> void:
	_close_inn_dialog()

func _close_inn_dialog() -> void:
	if _inn_dialog != null:
		_inn_dialog.queue_free()
		_inn_dialog = null

func _show_inn_feedback(msg: String) -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 31
	var lbl := Label.new()
	lbl.text = msg
	lbl.set_anchors_preset(Control.PRESET_CENTER)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 32)
	lbl.add_theme_color_override("font_color", Color(1, 1, 0.5, 1))
	canvas.add_child(lbl)
	add_child(canvas)
	await get_tree().create_timer(2.0).timeout
	canvas.queue_free()

func _check_random_event() -> void:
	match randi() % 3:
		0: _trigger_merchant()
		1: _trigger_chest()
		_: _trigger_helper_npc()

func _trigger_merchant() -> void:
	GameManager.merchant_discount = 0.8
	var popup = _event_popup_scene.instantiate()
	add_child(popup)
	popup.setup(Color(0.2, 0.4, 0.8, 1), "Marchand Itinérant\n\n-20% sur tous les articles !", "Ouvrir Boutique", true)
	popup.confirmed.connect(func():
		if _shop_open: return
		_shop_open = true
		var shop := _shop_scene.instantiate()
		shop.tree_exited.connect(func(): GameManager.merchant_discount = 1.0; _shop_open = false)
		get_tree().root.add_child(shop)
	)
	popup.closed.connect(func(): GameManager.merchant_discount = 1.0)

func _trigger_chest() -> void:
	var gold_found: int = 50 + randi() % 151
	GameManager.add_gold(gold_found)
	var popup = _event_popup_scene.instantiate()
	add_child(popup)
	popup.setup(Color(1.0, 0.85, 0.1, 1), "Coffre Caché\n\nVous avez trouvé %d Gil !" % gold_found, "Ouvrir")

func _trigger_helper_npc() -> void:
	var heal_amt: int = 30
	for m in GameManager.party:
		if m.is_alive():
			m.hp = min(m.max_hp, m.hp + heal_amt)
	var popup = _event_popup_scene.instantiate()
	add_child(popup)
	popup.setup(Color(0.2, 0.8, 0.3, 1), "Voyageur Mystérieux\n\n\"Voici de l'énergie, voyageur.\"\n+%d HP à tous !" % heal_amt, "Merci")

func _on_encounter() -> void:
	if randf() < RANDOM_EVENT_CHANCE:
		_check_random_event()
		return
	GameManager.return_after_battle = "res://scenes/world/WorldMap.tscn"
	BattleManager.is_boss_battle = false
	BattleManager.is_boss1_battle = false
	BattleManager.is_boss2_battle = false
	BattleManager.is_boss_sephiroth_battle = false
	BattleManager.is_ruby_weapon_battle = false
	BattleManager.is_emerald_weapon_battle = false
	BattleManager.sector_mode = ""
	BattleManager.dungeon_mode = false
	GameManager.change_scene("res://scenes/combat/Battle.tscn")

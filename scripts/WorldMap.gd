extends Node2D

const MAP_WIDTH := 3200.0
const MAP_HEIGHT := 3200.0
const CAMERA_LERP := 5.0

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D
@onready var joystick: Control = $VirtualJoystick
@onready var _pause_menu = $PauseMenu

var _shop_scene: PackedScene = preload("res://scenes/ui/Shop.tscn")
var _shop_open: bool = false
var _inn_dialog = null

func _ready() -> void:
	GameManager.set_state(GameManager.GameState.WORLD)
	AudioManager.play_world_bgm()
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

func _add_boss_buttons() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
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
	BattleManager.dungeon_mode = false
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

func _on_encounter() -> void:
	GameManager.return_after_battle = "res://scenes/world/WorldMap.tscn"
	BattleManager.is_boss_battle = false
	BattleManager.dungeon_mode = false
	GameManager.change_scene("res://scenes/combat/Battle.tscn")

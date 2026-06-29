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

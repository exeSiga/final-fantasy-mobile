extends Node2D

@onready var log_label: Label = $UI/LogPanel/LogLabel
@onready var hero_hp_bar: HPBar = $UI/HeroPanel/HeroHPBar
@onready var hero_hp_label: Label = $UI/HeroPanel/HeroHPLabel
@onready var hero_mp_label: Label = $UI/HeroPanel/HeroMPLabel
@onready var enemy_panel: VBoxContainer = $UI/EnemyPanel
@onready var action_buttons: HBoxContainer = $UI/ActionButtons
@onready var magic_menu: VBoxContainer = $UI/MagicMenu
@onready var item_menu: VBoxContainer = $UI/ItemMenu
@onready var popup_layer: CanvasLayer = $PopupLayer
@onready var victory_overlay: PanelContainer = $UI/VictoryOverlay
@onready var gameover_overlay: PanelContainer = $UI/GameOverOverlay

var _log_lines: PackedStringArray = []
var _enemy_hp_bars: Array[HPBar] = []

@onready var _bg: ColorRect = $Background

func _ready() -> void:
	victory_overlay.hide()
	gameover_overlay.hide()
	magic_menu.hide()
	item_menu.hide()
	_build_magic_menu()
	AudioManager.play_battle_bgm()
	BattleManager.battle_started.connect(_on_battle_started)
	BattleManager.action_result.connect(_on_action_result)
	BattleManager.turn_changed.connect(_on_turn_changed)
	BattleManager.battle_ended.connect(_on_battle_ended)
	BattleManager.start_battle(BattleManager._dungeon_mode, BattleManager.is_boss_battle)

func _on_battle_started(player: CombatUnit, enemies: Array) -> void:
	hero_hp_bar.set_unit(player)
	_refresh_hero_label(player)
	_build_enemy_bars(enemies)
	_log("Battle start!")

func _build_magic_menu() -> void:
	for child in magic_menu.get_children():
		if child.name != "CloseButton":
			child.queue_free()
	for spell in GameManager.spells:
		var btn := Button.new()
		btn.text = "%s  MP:%d" % [spell.spell_name, spell.mp_cost]
		btn.theme_override_font_sizes = {"font_size": 28}
		btn.pressed.connect(_on_spell_selected.bind(spell))
		magic_menu.add_child(btn)

func _on_turn_changed(unit: CombatUnit) -> void:
	action_buttons.visible = unit.is_player
	_log("%s's turn" % unit.unit_name)

func _on_action_result(attacker: String, target: String, damage: int) -> void:
	var player := BattleManager.player_unit
	if damage == -1:
		_log("Not enough MP!")
	elif damage <= 0 and damage > -1:
		_log("%s casts on %s" % [attacker, target])
		_spawn_popup("Buff!", Color(0.3, 0.8, 1, 1))
		AudioManager.play_sfx_spell()
	elif damage < 0:
		_log("%s heals %d HP" % [attacker, -damage])
		_spawn_popup("+%d HP" % (-damage), Color(0.3, 1, 0.3, 1))
		AudioManager.play_sfx_spell()
	else:
		_log("%s → %s : %d dmg" % [attacker, target, damage])
		_spawn_popup("-%d" % damage, Color(1, 0.3, 0.3, 1))
		AudioManager.play_sfx_attack()
		_shake_screen()
	hero_hp_bar.animate_to(player.hp)
	_refresh_hero_label(player)
	for i in BattleManager.enemies.size():
		if i < _enemy_hp_bars.size():
			_enemy_hp_bars[i].animate_to(BattleManager.enemies[i].hp)

func _shake_screen() -> void:
	var t := create_tween()
	t.tween_property(_bg, "position:x", 18.0, 0.04)
	t.tween_property(_bg, "position:x", -18.0, 0.04)
	t.tween_property(_bg, "position:x", 8.0, 0.04)
	t.tween_property(_bg, "position:x", 0.0, 0.04)

func _on_battle_ended(victory: bool) -> void:
	action_buttons.hide()
	magic_menu.hide()
	AudioManager.stop_bgm()
	if victory:
		AudioManager.play_sfx_victory()
		SaveSystem.save(0)
		var title := victory_overlay.get_node("VBox/TitleLabel") as Label
		title.text = "Victory!\n+%d XP  +%d G" % [BattleManager.last_xp, BattleManager.last_gold]
		victory_overlay.show()
	else:
		gameover_overlay.show()

func _build_enemy_bars(enemies: Array) -> void:
	for child in enemy_panel.get_children():
		child.queue_free()
	_enemy_hp_bars.clear()
	for e in enemies:
		var row := VBoxContainer.new()
		var name_lbl := Label.new()
		name_lbl.text = e.unit_name
		name_lbl.theme_override_font_sizes = {"font_size": 30}
		var bar: HPBar = preload("res://scenes/ui/HPBar.tscn").instantiate()
		bar.set_unit(e)
		row.add_child(name_lbl)
		row.add_child(bar)
		enemy_panel.add_child(row)
		_enemy_hp_bars.append(bar)

func _refresh_hero_label(player: CombatUnit) -> void:
	hero_hp_label.text = "HP  %d / %d" % [player.hp, player.max_hp]
	hero_mp_label.text = "MP  %d / %d" % [player.mp, player.max_mp]

func _log(msg: String) -> void:
	_log_lines.append(msg)
	if _log_lines.size() > 3:
		_log_lines.remove_at(0)
	log_label.text = "\n".join(_log_lines)

func _spawn_popup(text: String, color: Color) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.modulate = color
	lbl.theme_override_font_sizes = {"font_size": 52}
	lbl.position = Vector2(randf_range(400, 700), 600)
	popup_layer.add_child(lbl)
	var tween := lbl.create_tween()
	tween.tween_property(lbl, "position:y", lbl.position.y - 200, 0.8).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(lbl, "modulate:a", 0.0, 0.8).set_ease(Tween.EASE_IN)
	tween.tween_callback(lbl.queue_free)

func _on_attack_pressed() -> void:
	BattleManager.player_attack()

func _on_magic_pressed() -> void:
	action_buttons.hide()
	magic_menu.show()

func _on_spell_selected(spell: Spell) -> void:
	magic_menu.hide()
	action_buttons.show()
	BattleManager.player_cast_spell(spell)

func _on_magic_close_pressed() -> void:
	magic_menu.hide()
	action_buttons.show()

func _on_item_pressed() -> void:
	_build_item_menu()
	action_buttons.hide()
	item_menu.show()

func _build_item_menu() -> void:
	for child in item_menu.get_children():
		if child.name != "ItemCloseButton":
			child.queue_free()
	if GameManager.inventory.is_empty():
		var lbl := Label.new()
		lbl.text = "— Empty —"
		item_menu.add_child(lbl)
		return
	for key in GameManager.inventory:
		var item: Item = load(key)
		var qty: int = GameManager.inventory[key]
		var btn := Button.new()
		btn.text = "%s x%d" % [item.item_name, qty]
		btn.theme_override_font_sizes = {"font_size": 28}
		btn.pressed.connect(_on_item_used.bind(item))
		item_menu.add_child(btn)

func _on_item_used(item: Item) -> void:
	item_menu.hide()
	action_buttons.show()
	var ok := GameManager.use_item(item)
	if ok:
		_log("Used %s!" % item.item_name)
		_refresh_hero_label(BattleManager.player_unit)
		hero_hp_bar.animate_to(BattleManager.player_unit.hp)
		BattleManager.player_unit = GameManager.player_unit
		if BattleManager.state == BattleManager.BattleState.PLAYER_TURN:
			BattleManager._rebuild_and_next()
	else:
		_log("Can't use that now.")

func _on_item_close_pressed() -> void:
	item_menu.hide()
	action_buttons.show()

func _on_run_pressed() -> void:
	BattleManager.player_run()

func _on_victory_continue_pressed() -> void:
	GameManager.change_scene(GameManager.return_after_battle)

func _on_gameover_menu_pressed() -> void:
	GameManager.change_scene("res://scenes/ui/MainMenu.tscn")

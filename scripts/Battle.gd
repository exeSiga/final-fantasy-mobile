extends Node2D

@onready var log_label: Label     = $UI/LogPanel/LogLabel
@onready var enemy_panel          = $UI/EnemyPanel
@onready var hero_panel           = $UI/HeroPanel
@onready var action_buttons       = $UI/ActionButtons
@onready var magic_menu           = $UI/MagicMenu
@onready var item_menu            = $UI/ItemMenu
@onready var popup_layer          = $PopupLayer
@onready var victory_overlay      = $UI/VictoryOverlay
@onready var gameover_overlay     = $UI/GameOverOverlay
@onready var _victory_title: Label = $UI/VictoryOverlay/VBox/TitleLabel
@onready var _bg: ColorRect       = $Background
@onready var _enemy_root: Node2D  = $EnemySpriteRoot
@onready var _magic_btn: Button   = $UI/ActionButtons/MagicButton

@onready var _party_sprites: Array = [$PartySprite0, $PartySprite1, $PartySprite2]

const UnitSprite = preload("res://scripts/UnitSprite.gd")

var _log_lines: PackedStringArray = []
var _enemy_hp_bars: Array = []
var _enemy_sprite_list: Array = []

# Party panel rows — built dynamically
var _party_hp_bars: Array = []
var _party_hp_texts: Array = []
var _party_mp_texts: Array = []
var _party_name_labels: Array = []

var _active_party_idx: int = -1

func _ready() -> void:
	victory_overlay.hide()
	gameover_overlay.hide()
	magic_menu.hide()
	item_menu.hide()
	AudioManager.play_battle_bgm()
	BattleManager.battle_started.connect(_on_battle_started)
	BattleManager.action_result.connect(_on_action_result)
	BattleManager.turn_changed.connect(_on_turn_changed)
	BattleManager.battle_ended.connect(_on_battle_ended)
	BattleManager.start_battle(BattleManager.dungeon_mode, BattleManager.is_boss_battle)

func _on_battle_started(party: Array, enemies: Array) -> void:
	_build_party_panel(party)
	_build_party_sprites(party)
	_build_enemy_sprites(enemies)
	_build_enemy_bars(enemies)
	_log("Battle start!")

func _build_party_panel(party: Array) -> void:
	for child in hero_panel.get_children():
		child.queue_free()
	_party_hp_bars.clear()
	_party_hp_texts.clear()
	_party_mp_texts.clear()
	_party_name_labels.clear()
	for m in party:
		var row := HBoxContainer.new()
		var name_lbl := Label.new()
		name_lbl.text = m.unit_name
		name_lbl.custom_minimum_size = Vector2(160, 0)
		name_lbl.add_theme_font_size_override("font_size", 24)
		var hp_bar = preload("res://scenes/ui/HPBar.tscn").instantiate()
		hp_bar.set_unit(m)
		hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var hp_txt := Label.new()
		hp_txt.text = "%d/%d" % [m.hp, m.max_hp]
		hp_txt.custom_minimum_size = Vector2(120, 0)
		hp_txt.add_theme_font_size_override("font_size", 22)
		var mp_txt := Label.new()
		if m.max_mp > 0:
			mp_txt.text = "MP%d" % m.mp
		else:
			mp_txt.text = ""
		mp_txt.custom_minimum_size = Vector2(90, 0)
		mp_txt.add_theme_font_size_override("font_size", 22)
		mp_txt.add_theme_color_override("font_color", Color(0.4, 0.6, 1, 1))
		row.add_child(name_lbl)
		row.add_child(hp_bar)
		row.add_child(hp_txt)
		row.add_child(mp_txt)
		hero_panel.add_child(row)
		_party_hp_bars.append(hp_bar)
		_party_hp_texts.append(hp_txt)
		_party_mp_texts.append(mp_txt)
		_party_name_labels.append(name_lbl)

func _build_party_sprites(party: Array) -> void:
	for i in min(party.size(), _party_sprites.size()):
		_party_sprites[i].setup(party[i].sprite_color, party[i].unit_name)

func _build_enemy_sprites(enemies: Array) -> void:
	for child in _enemy_root.get_children():
		child.queue_free()
	_enemy_sprite_list.clear()
	var count := enemies.size()
	var xs: Array = []
	if count <= 1:
		xs = [540.0]
	elif count == 2:
		xs = [270.0, 810.0]
	else:
		xs = [180.0, 540.0, 900.0]
	for i in count:
		var spr := UnitSprite.new()
		spr.position = Vector2(xs[i], 400.0)
		spr.setup(enemies[i].sprite_color, enemies[i].unit_name)
		_enemy_root.add_child(spr)
		_enemy_sprite_list.append(spr)

func _update_enemy_sprites() -> void:
	for i in BattleManager.enemies.size():
		if i < _enemy_sprite_list.size():
			var e = BattleManager.enemies[i]
			_enemy_sprite_list[i].modulate.a = 0.25 if not e.is_alive() else 1.0

func _on_turn_changed(unit) -> void:
	var is_party_turn: bool = unit.is_player
	action_buttons.visible = is_party_turn
	if is_party_turn:
		_active_party_idx = _party_index_of(unit)
		_highlight_active_member()
		_rebuild_magic_button(unit)
	_log("%s's turn" % unit.unit_name)

func _party_index_of(unit) -> int:
	for i in BattleManager.party.size():
		if BattleManager.party[i] == unit:
			return i
	return -1

func _highlight_active_member() -> void:
	for i in _party_name_labels.size():
		var lbl = _party_name_labels[i]
		if i == _active_party_idx:
			lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2, 1))
		else:
			lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75, 1))
	for i in _party_sprites.size():
		_party_sprites[i].set_active(i == _active_party_idx)

func _rebuild_magic_button(unit) -> void:
	var has_spells: bool = unit.spell_paths.size() > 0
	_magic_btn.visible = has_spells
	if has_spells:
		_build_magic_menu(unit)

func _build_magic_menu(unit) -> void:
	for child in magic_menu.get_children():
		if child.name != "CloseButton":
			child.queue_free()
	for path in unit.spell_paths:
		var spell = load(path)
		var btn := Button.new()
		btn.text = "%s  MP:%d" % [spell.spell_name, spell.mp_cost]
		btn.add_theme_font_size_override("font_size", 28)
		btn.pressed.connect(_on_spell_selected.bind(spell))
		magic_menu.add_child(btn)

func _on_action_result(attacker: String, target: String, damage: int, is_crit: bool) -> void:
	if damage == -1:
		_log("Not enough MP!")
	elif damage < 0:
		_log("%s heals %s  +%d HP" % [attacker, target, -damage])
		_spawn_popup("+%d HP" % (-damage), Color(0.3, 1, 0.3, 1))
		AudioManager.play_sfx_spell()
	elif damage == 0:
		_log("%s → %s" % [attacker, target])
		_spawn_popup("Buff!", Color(0.3, 0.8, 1, 1))
		AudioManager.play_sfx_spell()
	else:
		var crit_str: String = " ★CRIT!" if is_crit else ""
		_log("%s → %s : %d%s" % [attacker, target, damage, crit_str])
		var pop_color := Color(1.0, 0.9, 0.1, 1) if is_crit else Color(1, 0.3, 0.3, 1)
		var pop_txt: String = "★%d" % damage if is_crit else "-%d" % damage
		_spawn_popup(pop_txt, pop_color)
		AudioManager.play_sfx_attack()
		_shake_screen()
	_refresh_party_ui()
	_update_enemy_sprites()
	for i in BattleManager.enemies.size():
		if i < _enemy_hp_bars.size():
			_enemy_hp_bars[i].animate_to(BattleManager.enemies[i].hp)

func _refresh_party_ui() -> void:
	var party = BattleManager.party
	for i in min(party.size(), _party_hp_bars.size()):
		var m = party[i]
		_party_hp_bars[i].animate_to(m.hp)
		_party_hp_texts[i].text = "%d/%d" % [m.hp, m.max_hp]
		if m.max_mp > 0:
			_party_mp_texts[i].text = "MP%d" % m.mp
		if not m.is_alive():
			_party_name_labels[i].add_theme_color_override("font_color", Color(0.4, 0.4, 0.4, 1))
			_party_sprites[i].modulate.a = 0.3

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
		_victory_title.text = "Victory!\n+%d XP  +%d G" % [BattleManager.last_xp, BattleManager.last_gold]
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
		name_lbl.add_theme_font_size_override("font_size", 26)
		var bar = preload("res://scenes/ui/HPBar.tscn").instantiate()
		bar.set_unit(e)
		row.add_child(name_lbl)
		row.add_child(bar)
		enemy_panel.add_child(row)
		_enemy_hp_bars.append(bar)

func _log(msg: String) -> void:
	_log_lines.append(msg)
	if _log_lines.size() > 3:
		_log_lines.remove_at(0)
	log_label.text = "\n".join(_log_lines)

func _spawn_popup(text: String, color: Color) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.modulate = color
	lbl.add_theme_font_size_override("font_size", 52)
	lbl.position = Vector2(randf_range(380, 700), 600)
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

func _on_spell_selected(spell) -> void:
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
		var item = load(key)
		var qty: int = GameManager.inventory[key]
		var btn := Button.new()
		btn.text = "%s x%d" % [item.item_name, qty]
		btn.add_theme_font_size_override("font_size", 28)
		btn.pressed.connect(_on_item_used.bind(item))
		item_menu.add_child(btn)

func _on_item_used(item) -> void:
	item_menu.hide()
	action_buttons.show()
	var ok: bool = GameManager.use_item(item)
	if ok:
		_log("Used %s!" % item.item_name)
		_refresh_party_ui()
		if BattleManager.state == BattleManager.BattleState.PLAYER_TURN:
			BattleManager._after_player_turn()
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

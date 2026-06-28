extends Node2D

@onready var log_label: Label = $UI/LogPanel/LogLabel
@onready var hero_hp_bar: HPBar = $UI/HeroPanel/HeroHPBar
@onready var hero_hp_label: Label = $UI/HeroPanel/HeroHPLabel
@onready var enemy_panel: VBoxContainer = $UI/EnemyPanel
@onready var action_buttons: HBoxContainer = $UI/ActionButtons
@onready var popup_layer: CanvasLayer = $PopupLayer
@onready var victory_overlay: PanelContainer = $UI/VictoryOverlay
@onready var gameover_overlay: PanelContainer = $UI/GameOverOverlay

var _log_lines: PackedStringArray = []
var _enemy_hp_bars: Array[HPBar] = []

func _ready() -> void:
	victory_overlay.hide()
	gameover_overlay.hide()
	BattleManager.battle_started.connect(_on_battle_started)
	BattleManager.action_result.connect(_on_action_result)
	BattleManager.turn_changed.connect(_on_turn_changed)
	BattleManager.battle_ended.connect(_on_battle_ended)
	BattleManager.start_battle()

func _on_battle_started(player: CombatUnit, enemies: Array) -> void:
	hero_hp_bar.set_unit(player)
	_refresh_hero_label(player)
	_build_enemy_bars(enemies)
	_log("Battle start!")

func _on_turn_changed(unit: CombatUnit) -> void:
	action_buttons.visible = unit.is_player
	_log("%s's turn" % unit.unit_name)

func _on_action_result(attacker: String, target: String, damage: int) -> void:
	_log("%s → %s : %d dmg" % [attacker, target, damage])
	var player := BattleManager.player_unit
	hero_hp_bar.animate_to(player.hp)
	_refresh_hero_label(player)
	for i in BattleManager.enemies.size():
		if i < _enemy_hp_bars.size():
			_enemy_hp_bars[i].animate_to(BattleManager.enemies[i].hp)
	_spawn_popup("-%d" % damage, Color(1, 0.3, 0.3, 1))

func _on_battle_ended(victory: bool) -> void:
	action_buttons.hide()
	if victory:
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
	_log("No spells learned yet.")

func _on_item_pressed() -> void:
	_log("No items in bag.")

func _on_run_pressed() -> void:
	BattleManager.player_run()

func _on_victory_continue_pressed() -> void:
	GameManager.change_scene("res://scenes/world/WorldMap.tscn")

func _on_gameover_menu_pressed() -> void:
	GameManager.change_scene("res://scenes/ui/MainMenu.tscn")

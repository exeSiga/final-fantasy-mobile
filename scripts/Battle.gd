extends Node2D

@onready var log_label: Label = $UI/LogPanel/LogLabel
@onready var hero_hp_label: Label = $UI/HeroPanel/HPLabel
@onready var enemy_panel: VBoxContainer = $UI/EnemyPanel
@onready var action_buttons: HBoxContainer = $UI/ActionButtons

var _log_lines: PackedStringArray = []

func _ready() -> void:
	BattleManager.battle_started.connect(_on_battle_started)
	BattleManager.action_result.connect(_on_action_result)
	BattleManager.turn_changed.connect(_on_turn_changed)
	BattleManager.battle_ended.connect(_on_battle_ended)
	BattleManager.start_battle()

func _on_battle_started(player: CombatUnit, enemies: Array) -> void:
	_refresh_hero_hp(player)
	_refresh_enemies(enemies)
	_log("Battle start!")

func _on_turn_changed(unit: CombatUnit) -> void:
	action_buttons.visible = unit.is_player
	_log("%s's turn" % unit.unit_name)

func _on_action_result(attacker: String, target: String, damage: int) -> void:
	_log("%s hits %s for %d dmg" % [attacker, target, damage])
	_refresh_hero_hp(BattleManager.player_unit)
	_refresh_enemies(BattleManager.enemies)

func _on_battle_ended(victory: bool) -> void:
	action_buttons.visible = false
	if victory:
		_log("Victory!")
		await get_tree().create_timer(2.0).timeout
		GameManager.change_scene("res://scenes/world/WorldMap.tscn")
	else:
		_log("Defeated...")
		await get_tree().create_timer(2.0).timeout
		GameManager.change_scene("res://scenes/ui/MainMenu.tscn")

func _refresh_hero_hp(player: CombatUnit) -> void:
	hero_hp_label.text = "HP: %d / %d" % [player.hp, player.max_hp]

func _refresh_enemies(enemies: Array) -> void:
	for child in enemy_panel.get_children():
		child.queue_free()
	for e in enemies:
		var lbl := Label.new()
		lbl.text = "%s  HP:%d/%d" % [e.unit_name, e.hp, e.max_hp]
		if not e.is_alive():
			lbl.modulate = Color(0.4, 0.4, 0.4, 1)
		enemy_panel.add_child(lbl)

func _log(msg: String) -> void:
	_log_lines.append(msg)
	if _log_lines.size() > 3:
		_log_lines.remove_at(0)
	log_label.text = "\n".join(_log_lines)

func _on_attack_pressed() -> void:
	BattleManager.player_attack()

func _on_run_pressed() -> void:
	BattleManager.player_run()

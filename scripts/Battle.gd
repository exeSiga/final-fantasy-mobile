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
@onready var _attack_btn: Button  = $UI/ActionButtons/AttackButton

@onready var _party_sprites: Array = [$PartySprite0, $PartySprite1, $PartySprite2]
@onready var _target_menu: VBoxContainer  = $UI/TargetMenu
@onready var _target_list: VBoxContainer  = $UI/TargetMenu/TargetList
@onready var _summon_menu: VBoxContainer  = $UI/SummonMenu
@onready var _summon_btn: Button          = $UI/ActionButtons/SummonButton

const UnitSprite = preload("res://scripts/UnitSprite.gd")

var _log_lines: PackedStringArray = []
var _enemy_hp_bars: Array = []
var _enemy_sprite_list: Array = []
var _wave_label: Label = null
var _wave_canvas: CanvasLayer = null
var _weather_label: Label = null
var _last_quote_idx: int = -1

# Party panel rows — built dynamically
var _party_hp_bars: Array = []
var _party_hp_texts: Array = []
var _party_mp_texts: Array = []
var _party_name_labels: Array = []
var _party_limit_labels: Array = []
var _party_atb_bars: Array = []

var _limit_btn: Button = null
var _bigshot_btn: Button = null
var _lunatic_btn: Button = null
var _shuriken_btn: Button = null
var _steal_btn: Button = null
var _galian_btn: Button = null
var _slot_btn: Button = null

var _active_party_idx: int = -1
var _pending_cutscene: String = ""
var _victory_continue_clicked: bool = false

func _ready() -> void:
	victory_overlay.hide()
	gameover_overlay.hide()
	magic_menu.hide()
	item_menu.hide()
	_summon_menu.hide()
	_create_limit_button()
	_create_bigshot_button()
	_create_lunatic_button()
	_create_shuriken_button()
	_create_steal_button()
	_create_galian_button()
	_create_slot_button()
	_fade_in()
	AudioManager.play_battle_bgm()
	BattleManager.battle_started.connect(_on_battle_started)
	BattleManager.action_result.connect(_on_action_result)
	BattleManager.turn_changed.connect(_on_turn_changed)
	BattleManager.battle_ended.connect(_on_battle_ended)
	BattleManager.battle_log.connect(_log)
	BattleManager.limit_gauge_updated.connect(_on_limit_gauge_updated)
	BattleManager.summon_triggered.connect(_on_summon_triggered)
	BattleManager.atb_updated.connect(_on_atb_updated)
	BattleManager.atb_ready.connect(_on_atb_ready)
	BattleManager.enemy_skill_learned.connect(_on_enemy_skill_learned)
	BattleManager.arena_wave_cleared.connect(_on_arena_wave_cleared)
	BattleManager.weather_changed.connect(_on_weather_changed)
	GameManager.level_up.connect(_on_level_up)
	_setup_ember_particles()
	_setup_floor_strip()
	if BattleManager.arena_mode:
		BattleManager.start_arena()
	elif BattleManager.sector_mode != "":
		BattleManager.start_sector_battle(BattleManager.sector_mode)
	else:
		BattleManager.start_battle(BattleManager.dungeon_mode, BattleManager.is_boss_battle)

func _setup_ember_particles() -> void:
	var particles := CPUParticles2D.new()
	particles.amount = 22
	particles.lifetime = 4.0
	particles.explosiveness = 0.0
	particles.randomness = 1.0
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(540, 8)
	particles.position = Vector2(540, 1860)
	particles.direction = Vector2(0.0, -1.0)
	particles.spread = 22.0
	particles.gravity = Vector2(6.0, -12.0)
	particles.initial_velocity_min = 35.0
	particles.initial_velocity_max = 110.0
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 6.0
	var grad := Gradient.new()
	grad.colors = PackedColorArray([
		Color(1.00, 0.80, 0.20, 1.00),
		Color(1.00, 0.30, 0.05, 0.60),
		Color(0.30, 0.05, 0.00, 0.00)
	])
	grad.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	particles.color_ramp = grad
	add_child(particles)

func _setup_floor_strip() -> void:
	var tex: Texture2D = load("res://assets/Tiny Dungeon/Tiles/tile_0001.png")
	if tex == null:
		return
	var strip := TextureRect.new()
	strip.texture = tex
	strip.stretch_mode = TextureRect.STRETCH_TILE
	strip.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	strip.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	strip.position = Vector2(0.0, 1350.0)
	strip.size = Vector2(180.0, 95.0)
	strip.scale = Vector2(6.0, 6.0)
	strip.modulate = Color(0.65, 0.50, 0.35, 0.50)
	add_child(strip)
	move_child(strip, 1)

func _fade_in() -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 1)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	var canvas := CanvasLayer.new()
	canvas.layer = 100
	add_child(canvas)
	canvas.add_child(overlay)
	var tw := overlay.create_tween()
	tw.tween_property(overlay, "color:a", 0.0, 0.4)
	tw.tween_callback(canvas.queue_free)

func _create_limit_button() -> void:
	_limit_btn = Button.new()
	_limit_btn.text = "⚡ LIMIT"
	_limit_btn.add_theme_font_size_override("font_size", 28)
	_limit_btn.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0, 1.0))
	_limit_btn.custom_minimum_size = Vector2(160, 0)
	_limit_btn.visible = false
	_limit_btn.pressed.connect(_on_limit_pressed)
	action_buttons.add_child(_limit_btn)
	action_buttons.move_child(_limit_btn, 0)

func _ensure_wave_label() -> void:
	if _wave_canvas != null:
		return
	_wave_canvas = CanvasLayer.new()
	_wave_canvas.layer = 10
	add_child(_wave_canvas)
	_wave_label = Label.new()
	_wave_label.add_theme_font_size_override("font_size", 36)
	_wave_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1))
	_wave_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_wave_label.offset_left = -260.0
	_wave_label.offset_top = 10.0
	_wave_label.offset_right = -10.0
	_wave_label.offset_bottom = 60.0
	_wave_canvas.add_child(_wave_label)

func _on_battle_started(party: Array, enemies: Array) -> void:
	_build_party_panel(party)
	_build_party_sprites(party)
	_build_enemy_sprites(enemies)
	_build_enemy_bars(enemies)
	_ensure_weather_label()
	_update_weather_display(BattleManager.current_weather)
	if BattleManager.arena_mode:
		_ensure_wave_label()
		_wave_label.text = "Vague %d/8" % BattleManager.arena_wave
		_wave_label.show()
		_log("Vague %d/8 — En garde !" % BattleManager.arena_wave)
	else:
		_log("Battle start!")

func _ensure_weather_label() -> void:
	if _weather_label != null:
		return
	_weather_label = Label.new()
	_weather_label.add_theme_font_size_override("font_size", 22)
	_weather_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0, 1))
	_weather_label.position = Vector2(10, 10)
	add_child(_weather_label)

func _update_weather_display(weather: String) -> void:
	if _weather_label == null:
		return
	var icon: String = BattleManager.WEATHER_ICONS.get(weather, "")
	_weather_label.text = "%s %s" % [icon, weather.capitalize()]
	_weather_label.visible = (weather != "clear")

func _on_weather_changed(weather: String) -> void:
	_update_weather_display(weather)

func _build_party_panel(party: Array) -> void:
	for child in hero_panel.get_children():
		child.queue_free()
	_party_hp_bars.clear()
	_party_hp_texts.clear()
	_party_mp_texts.clear()
	_party_name_labels.clear()
	_party_limit_labels.clear()
	_party_atb_bars.clear()
	for m in party:
		var member_box := VBoxContainer.new()
		member_box.add_theme_constant_override("separation", 2)
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
		var lmt_txt := Label.new()
		lmt_txt.text = "⚡%d" % m.limit_gauge
		lmt_txt.custom_minimum_size = Vector2(75, 0)
		lmt_txt.add_theme_font_size_override("font_size", 20)
		lmt_txt.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0, 1.0))
		row.add_child(name_lbl)
		row.add_child(hp_bar)
		row.add_child(hp_txt)
		row.add_child(mp_txt)
		row.add_child(lmt_txt)
		member_box.add_child(row)
		var atb_bar := ProgressBar.new()
		atb_bar.min_value = 0.0
		atb_bar.max_value = 100.0
		atb_bar.value = 0.0
		atb_bar.show_percentage = false
		atb_bar.custom_minimum_size = Vector2(0, 10)
		atb_bar.modulate = Color(0.3, 0.85, 1.0, 1)
		member_box.add_child(atb_bar)
		hero_panel.add_child(member_box)
		_party_hp_bars.append(hp_bar)
		_party_hp_texts.append(hp_txt)
		_party_mp_texts.append(mp_txt)
		_party_name_labels.append(name_lbl)
		_party_limit_labels.append(lmt_txt)
		_party_atb_bars.append(atb_bar)

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

func _create_bigshot_button() -> void:
	_bigshot_btn = Button.new()
	_bigshot_btn.text = "Big Shot"
	_bigshot_btn.add_theme_font_size_override("font_size", 28)
	_bigshot_btn.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2, 1.0))
	_bigshot_btn.custom_minimum_size = Vector2(160, 0)
	_bigshot_btn.visible = false
	_bigshot_btn.pressed.connect(_on_bigshot_pressed)
	action_buttons.add_child(_bigshot_btn)

func _create_lunatic_button() -> void:
	_lunatic_btn = Button.new()
	_lunatic_btn.text = "Lunatic High"
	_lunatic_btn.add_theme_font_size_override("font_size", 28)
	_lunatic_btn.add_theme_color_override("font_color", Color(0.85, 0.35, 0.1, 1.0))
	_lunatic_btn.custom_minimum_size = Vector2(180, 0)
	_lunatic_btn.visible = false
	_lunatic_btn.pressed.connect(_on_lunatic_pressed)
	action_buttons.add_child(_lunatic_btn)

func _create_shuriken_button() -> void:
	_shuriken_btn = Button.new()
	_shuriken_btn.text = "Shuriken"
	_shuriken_btn.add_theme_font_size_override("font_size", 28)
	_shuriken_btn.add_theme_color_override("font_color", Color(0.9, 0.85, 0.1, 1.0))
	_shuriken_btn.custom_minimum_size = Vector2(160, 0)
	_shuriken_btn.visible = false
	_shuriken_btn.pressed.connect(_on_shuriken_pressed)
	action_buttons.add_child(_shuriken_btn)

func _create_steal_button() -> void:
	_steal_btn = Button.new()
	_steal_btn.text = "Steal"
	_steal_btn.add_theme_font_size_override("font_size", 28)
	_steal_btn.add_theme_color_override("font_color", Color(0.6, 0.9, 0.3, 1.0))
	_steal_btn.custom_minimum_size = Vector2(130, 0)
	_steal_btn.visible = false
	_steal_btn.pressed.connect(_on_steal_pressed)
	action_buttons.add_child(_steal_btn)

func _create_galian_button() -> void:
	_galian_btn = Button.new()
	_galian_btn.text = "Galian Beast"
	_galian_btn.add_theme_font_size_override("font_size", 28)
	_galian_btn.add_theme_color_override("font_color", Color(0.85, 0.15, 0.15, 1.0))
	_galian_btn.custom_minimum_size = Vector2(180, 0)
	_galian_btn.visible = false
	_galian_btn.pressed.connect(_on_galian_pressed)
	action_buttons.add_child(_galian_btn)

func _on_turn_changed(unit) -> void:
	var is_party_turn: bool = unit.is_player
	action_buttons.visible = false
	if is_party_turn:
		_active_party_idx = _party_index_of(unit)
		_highlight_active_member()
		_rebuild_magic_button(unit)
		_update_limit_button(unit)
		_update_bigshot_button(unit)
		_update_lunatic_button(unit)
		_update_ninja_buttons(unit)
		_update_galian_button(unit)
		_update_slot_button(unit)
		_update_summon_button()
		_update_element_indicator(unit)
	_log("%s's turn" % unit.unit_name)

func _on_atb_ready(unit) -> void:
	if BattleManager.state == BattleManager.BattleState.PLAYER_TURN and unit == BattleManager.player_unit:
		action_buttons.visible = true

func _on_atb_updated(unit, value: float) -> void:
	var idx := _party_index_of(unit)
	if idx >= 0 and idx < _party_atb_bars.size():
		_party_atb_bars[idx].value = value

func _update_bigshot_button(unit) -> void:
	if _bigshot_btn == null:
		return
	_bigshot_btn.visible = (unit.character_class == "Gunner")

func _update_lunatic_button(unit) -> void:
	if _lunatic_btn == null:
		return
	_lunatic_btn.visible = (unit.character_class == "Beastmaster")

func _update_ninja_buttons(unit) -> void:
	var is_ninja: bool = unit.character_class == "Ninja"
	if _shuriken_btn != null:
		_shuriken_btn.visible = is_ninja
	if _steal_btn != null:
		_steal_btn.visible = is_ninja

func _update_galian_button(unit) -> void:
	if _galian_btn == null:
		return
	var is_dark: bool = unit.character_class == "DarkWarrior"
	_galian_btn.visible = is_dark
	if is_dark and unit.galian_turns > 0:
		_galian_btn.text = "Galian (%d)" % unit.galian_turns
	elif is_dark:
		_galian_btn.text = "Galian Beast"

func _update_limit_button(unit) -> void:
	if _limit_btn == null:
		return
	var ready: bool = unit.limit_gauge >= 100
	_limit_btn.visible = ready
	_attack_btn.visible = not ready
	if ready:
		_limit_btn.text = "⚡ %s" % BattleManager._limit_name(unit)

func _on_limit_gauge_updated(unit) -> void:
	_refresh_party_ui()
	if BattleManager.player_unit != null and BattleManager.player_unit == unit:
		_update_limit_button(unit)

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

func _find_enemy_sprite(name: String):
	for i in BattleManager.enemies.size():
		if BattleManager.enemies[i].unit_name == name and i < _enemy_sprite_list.size():
			return _enemy_sprite_list[i]
	return null

func _find_party_sprite(name: String):
	for i in BattleManager.party.size():
		if BattleManager.party[i].unit_name == name and i < _party_sprites.size():
			return _party_sprites[i]
	return null

func _on_action_result(attacker: String, target: String, damage: int, is_crit: bool) -> void:
	if damage == -1:
		_log("Not enough MP!")
	elif damage < 0:
		_log("%s heals %s  +%d HP" % [attacker, target, -damage])
		_spawn_popup("+%d HP" % (-damage), Color(0.3, 1, 0.3, 1))
		AudioManager.play_sfx_spell()
		var spr = _find_party_sprite(target)
		if spr:
			spr.flash(Color(0.1, 1.0, 0.3))
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
		_shake_screen(18.0 if not is_crit else 32.0)
		var flash_color := Color(1.0, 0.9, 0.1) if is_crit else Color(1, 1, 1)
		var enemy_spr = _find_enemy_sprite(target)
		if enemy_spr:
			enemy_spr.flash(flash_color)
			_animate_attack(enemy_spr, -1.0)
			if not BattleManager.enemies.any(func(e) -> bool: return e.unit_name == target and e.is_alive()):
				_spawn_death_particles(enemy_spr.global_position)
		var party_spr = _find_party_sprite(target)
		if party_spr:
			party_spr.flash(Color(1.0, 0.3, 0.3))
			var attacker_spr = _find_party_sprite(attacker)
			if attacker_spr:
				_animate_attack(attacker_spr, 1.0)
	_refresh_party_ui()
	_update_enemy_sprites()
	for i in BattleManager.enemies.size():
		if i < _enemy_hp_bars.size():
			_enemy_hp_bars[i].animate_to(BattleManager.enemies[i].hp)

func _on_enemy_skill_learned(spell_name: String) -> void:
	_spawn_popup("★ Appris : %s !" % spell_name, Color(0.4, 1.0, 0.6, 1))

func _on_level_up(new_level: int) -> void:
	_spawn_popup("★ LEVEL UP! Lv.%d ★" % new_level, Color(1.0, 0.9, 0.1, 1))

func _refresh_party_ui() -> void:
	var party = BattleManager.party
	for i in min(party.size(), _party_hp_bars.size()):
		var m = party[i]
		_party_hp_bars[i].animate_to(m.hp)
		_party_hp_texts[i].text = "%d/%d" % [m.hp, m.max_hp]
		if m.max_mp > 0:
			_party_mp_texts[i].text = "MP%d" % m.mp
		if i < _party_limit_labels.size():
			var lmt = _party_limit_labels[i]
			lmt.text = "⚡%d" % m.limit_gauge
			var full_color := Color(1.0, 0.85, 0.0, 1.0) if m.limit_gauge >= 100 else Color(0.7, 0.6, 0.2, 1.0)
			lmt.add_theme_color_override("font_color", full_color)
		var status_tag: String = ""
		match m.status:
			"poison":  status_tag = " [PSN]"
			"sleep":   status_tag = " [SLP]"
			"silence": status_tag = " [SIL]"
		if m.stop_turns > 0:   status_tag += " 🔴"
		if m.berserk_turns > 0: status_tag += " 🟡"
		if m.confuse_turns > 0: status_tag += " 🔵"
		_party_name_labels[i].text = m.unit_name + status_tag
		if not m.is_alive():
			_party_name_labels[i].add_theme_color_override("font_color", Color(0.4, 0.4, 0.4, 1))
			_party_sprites[i].modulate.a = 0.3

func _shake_screen(intensity: float = 18.0) -> void:
	var t := create_tween()
	t.tween_property(_bg, "position:x", intensity, 0.04)
	t.tween_property(_bg, "position:x", -intensity, 0.04)
	t.tween_property(_bg, "position:x", intensity * 0.5, 0.04)
	t.tween_property(_bg, "position:x", 0.0, 0.04)

func _spawn_death_particles(pos: Vector2) -> void:
	for i in 6:
		var dot := ColorRect.new()
		dot.size = Vector2(8, 8)
		dot.color = Color(randf_range(0.8, 1.0), randf_range(0.2, 0.6), 0.1, 1)
		dot.position = pos + Vector2(randf_range(-40, 40), randf_range(-40, 40))
		popup_layer.add_child(dot)
		var tw := dot.create_tween()
		var drift := Vector2(randf_range(-80, 80), randf_range(-120, -20))
		tw.tween_property(dot, "position", dot.position + drift, 0.6).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(dot, "modulate:a", 0.0, 0.6).set_ease(Tween.EASE_IN)
		tw.tween_callback(dot.queue_free)

func _animate_attack(spr: Node2D, direction: float) -> void:
	if spr == null:
		return
	var origin: Vector2 = spr.position
	var tw := create_tween()
	tw.tween_property(spr, "position:x", origin.x + direction * 20.0, 0.08)
	tw.tween_property(spr, "position:x", origin.x, 0.08)

func _on_arena_wave_cleared(wave: int) -> void:
	_log("Vague %d terminée ! Soin 20%% HP/MP..." % wave)
	_spawn_popup("Vague %d !" % wave, Color(0.3, 1.0, 0.5, 1))
	await get_tree().create_timer(1.5).timeout
	BattleManager._next_arena_wave()

func _on_battle_ended(victory: bool) -> void:
	action_buttons.hide()
	magic_menu.hide()
	AudioManager.stop_bgm()
	if victory:
		if BattleManager.is_boss1_battle and not GameManager.scene_reactor_done:
			GameManager.scene_reactor_done = true
			_pending_cutscene = "cutscene_reactor"
		elif BattleManager.is_boss2_battle and not GameManager.scene_jenova_done:
			GameManager.scene_jenova_done = true
			_pending_cutscene = "cutscene_jenova"
		AudioManager.play_sfx_victory()
		SaveSystem.save(0)
		if BattleManager.arena_completed:
			BattleManager.arena_completed = false
			_victory_title.text = "Champion de l'Arène !\n★ Champion Belt obtenu !\n+%d XP  +%d G" % [BattleManager.last_xp, BattleManager.last_gold]
		elif BattleManager.is_boss_sephiroth_battle:
			GameManager.ng_plus_unlocked = true
			_victory_title.text = "Sephiroth vaincu !\nLa planète est sauvée.\n+%d XP  +%d G" % [BattleManager.last_xp, BattleManager.last_gold]
			var ng_vbox = victory_overlay.get_node("VBox")
			var ng_btn := Button.new()
			ng_btn.text = "✨ New Game+"
			ng_btn.add_theme_font_size_override("font_size", 32)
			ng_btn.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1))
			ng_btn.custom_minimum_size = Vector2(300, 80)
			ng_btn.pressed.connect(_on_ng_plus_pressed)
			ng_vbox.add_child(ng_btn)
			ng_vbox.move_child(ng_btn, 1)
		elif BattleManager.is_ruby_weapon_battle:
			_victory_title.text = "Ruby Weapon vaincu !\n★ Ruby Ring obtenu !\n+%d XP  +%d G" % [BattleManager.last_xp, BattleManager.last_gold]
		elif BattleManager.is_emerald_weapon_battle:
			_victory_title.text = "Emerald Weapon vaincu !\n★ Emerald Bangle obtenu !\n+%d XP  +%d G" % [BattleManager.last_xp, BattleManager.last_gold]
		else:
			_victory_title.text = "Victory!\n+%d XP  +%d G" % [BattleManager.last_xp, BattleManager.last_gold]
		victory_overlay.show()
	else:
		_show_gameover()
		_fade_out()

func _fade_out() -> void:
	await get_tree().create_timer(1.2).timeout
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	var canvas := CanvasLayer.new()
	canvas.layer = 100
	add_child(canvas)
	canvas.add_child(overlay)
	var tw := overlay.create_tween()
	tw.tween_property(overlay, "color:a", 1.0, 0.4)

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

func _on_bigshot_pressed() -> void:
	action_buttons.hide()
	_shake_screen(24.0)
	BattleManager.player_bigshot()

func _on_lunatic_pressed() -> void:
	action_buttons.hide()
	_spawn_popup("★ Lunatic High!", Color(0.85, 0.35, 0.1, 1))
	BattleManager.player_lunatic_high()

func _on_shuriken_pressed() -> void:
	action_buttons.hide()
	_shake_screen(16.0)
	BattleManager.player_shuriken_throw()

func _on_steal_pressed() -> void:
	action_buttons.hide()
	_show_target_select("enemy", func(t) -> void: BattleManager.player_steal(t))

func _on_galian_pressed() -> void:
	action_buttons.hide()
	_shake_screen(20.0)
	_spawn_popup("Galian Beast!", Color(0.85, 0.15, 0.15, 1))
	BattleManager.player_galian_beast()

func _create_slot_button() -> void:
	_slot_btn = Button.new()
	_slot_btn.text = "🎰 Slot"
	_slot_btn.add_theme_font_size_override("font_size", 28)
	_slot_btn.add_theme_color_override("font_color", Color(1.0, 0.8, 0.1, 1.0))
	_slot_btn.custom_minimum_size = Vector2(130, 0)
	_slot_btn.visible = false
	_slot_btn.pressed.connect(_on_slot_pressed)
	action_buttons.add_child(_slot_btn)

func _update_slot_button(unit) -> void:
	if _slot_btn != null:
		_slot_btn.visible = (unit.character_class == "Machinist")

func _on_slot_pressed() -> void:
	action_buttons.hide()
	_spawn_popup("🎰 Slot !", Color(1.0, 0.8, 0.1, 1))
	BattleManager.player_slot_machine()

func _on_limit_pressed() -> void:
	action_buttons.hide()
	_shake_screen(48.0)
	BattleManager.player_limit_break()

func _on_attack_pressed() -> void:
	action_buttons.hide()
	_show_target_select("enemy", func(t) -> void: BattleManager.player_attack(t))

func _on_magic_pressed() -> void:
	action_buttons.hide()
	magic_menu.show()

func _on_spell_selected(spell) -> void:
	magic_menu.hide()
	match spell.effect_type:
		0:  # DAMAGE — pick enemy
			_show_target_select("enemy", func(t) -> void: BattleManager.player_cast_spell(spell, t))
		1:  # HEAL — pick alive ally
			_show_target_select("ally_alive", func(t) -> void: BattleManager.player_cast_spell(spell, t))
		2:  # HASTE — pick alive ally (any member can be hasted)
			_show_target_select("ally_alive", func(t) -> void: BattleManager.player_cast_spell(spell, t))
		3:  # REVIVE — pick dead ally
			_show_target_select("ally_dead", func(t) -> void: BattleManager.player_cast_spell(spell, t))
		_:
			action_buttons.show()
			BattleManager.player_cast_spell(spell, null)

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

func _show_target_select(mode: String, callback: Callable) -> void:
	for c in _target_list.get_children():
		c.queue_free()
	var targets: Array = []
	match mode:
		"enemy":
			targets = BattleManager.enemies.filter(func(e) -> bool: return e.is_alive())
		"ally_alive":
			targets = BattleManager.party.filter(func(m) -> bool: return m.is_alive())
		"ally_dead":
			targets = BattleManager.party.filter(func(m) -> bool: return not m.is_alive())
	if targets.is_empty():
		action_buttons.show()
		return
	for target in targets:
		var btn := Button.new()
		if mode == "enemy":
			btn.text = target.unit_name
		else:
			btn.text = "%s  %d/%d HP" % [target.unit_name, target.hp, target.max_hp]
		btn.add_theme_font_size_override("font_size", 30)
		btn.custom_minimum_size = Vector2(0, 80)
		btn.pressed.connect(_on_target_picked.bind(target, callback))
		_target_list.add_child(btn)
	_target_menu.show()

func _on_target_picked(target, callback: Callable) -> void:
	if BattleManager.state != BattleManager.BattleState.PLAYER_TURN:
		_target_menu.hide()
		return
	_target_menu.hide()
	action_buttons.show()
	callback.call(target)

func _on_target_cancel_pressed() -> void:
	_target_menu.hide()
	action_buttons.show()

func _on_item_close_pressed() -> void:
	item_menu.hide()
	action_buttons.show()

func _update_summon_button() -> void:
	var available: Array = BattleManager._get_available_summons()
	_summon_btn.visible = available.size() > 0

func _on_summon_pressed() -> void:
	action_buttons.hide()
	_show_summon_menu()

func _show_summon_menu() -> void:
	for c in _summon_menu.get_children():
		if c.name != "SummonCloseButton":
			c.queue_free()
	var available: Array = BattleManager._get_available_summons()
	for mat_path in available:
		var mat = load(mat_path)
		var btn := Button.new()
		btn.text = "%s — %s" % [mat.materia_name, mat.description]
		btn.add_theme_font_size_override("font_size", 28)
		btn.add_theme_color_override("font_color", Color(0.9, 0.7, 1.0, 1))
		btn.pressed.connect(_on_summon_selected.bind(mat_path))
		_summon_menu.add_child(btn)
	_summon_menu.show()

func _on_summon_selected(mat_path: String) -> void:
	_summon_menu.hide()
	action_buttons.show()
	BattleManager.player_summon(mat_path)

func _on_summon_close_pressed() -> void:
	_summon_menu.hide()
	action_buttons.show()

func _on_summon_triggered(summon_name: String, element: String) -> void:
	_animate_summon_flash(element)
	_shake_screen(24.0)
	_spawn_popup("★ %s!" % summon_name, Color(0.9, 0.7, 1.0, 1))

func _animate_summon_flash(element: String) -> void:
	var color: Color
	match element:
		"fire":      color = Color(1.0, 0.4, 0.0, 0.5)
		"ice":       color = Color(0.4, 0.8, 1.0, 0.5)
		"lightning": color = Color(1.0, 1.0, 0.2, 0.5)
		_:           color = Color(0.6, 0.2, 1.0, 0.5)
	var overlay := ColorRect.new()
	overlay.color = color
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup_layer.add_child(overlay)
	var tw := overlay.create_tween()
	tw.tween_property(overlay, "color:a", 0.0, 0.3)
	tw.tween_callback(overlay.queue_free)

func _on_run_pressed() -> void:
	BattleManager.player_run()

func _on_victory_continue_pressed() -> void:
	if _victory_continue_clicked:
		return
	_victory_continue_clicked = true
	if _pending_cutscene != "":
		var scene_id: String = _pending_cutscene
		_pending_cutscene = ""
		victory_overlay.hide()
		DialogueManager.show_dialogue(self, scene_id, "")
		DialogueManager.dialogue_finished.connect(_on_cutscene_ended, CONNECT_ONE_SHOT)
	else:
		GameManager.change_scene(GameManager.return_after_battle)

func _on_cutscene_ended() -> void:
	GameManager.change_scene(GameManager.return_after_battle)

func _show_gameover() -> void:
	var vbox = gameover_overlay.get_node("VBox")
	# Add Sephiroth quote
	var quotes: Array = BattleManager.SEPHIROTH_QUOTES
	var idx: int = randi() % quotes.size()
	if quotes.size() > 1:
		while idx == _last_quote_idx:
			idx = randi() % quotes.size()
	_last_quote_idx = idx
	var quote_lbl := Label.new()
	quote_lbl.text = "— %s" % quotes[idx]
	quote_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quote_lbl.add_theme_font_size_override("font_size", 26)
	quote_lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 1.0, 1))
	quote_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(quote_lbl)
	vbox.move_child(quote_lbl, 1)
	# Add Retry button
	var retry_btn := Button.new()
	retry_btn.text = "Réessayer (50% HP)"
	retry_btn.add_theme_font_size_override("font_size", 32)
	retry_btn.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5, 1))
	retry_btn.custom_minimum_size = Vector2(300, 80)
	retry_btn.pressed.connect(_on_gameover_retry_pressed)
	vbox.add_child(retry_btn)
	vbox.move_child(retry_btn, 2)
	gameover_overlay.show()

func _on_gameover_retry_pressed() -> void:
	# Clean up dynamic widgets before retry
	var vbox = gameover_overlay.get_node("VBox")
	for c in vbox.get_children():
		if c.name != "TitleLabel" and c.name != "MenuButton":
			c.queue_free()
	gameover_overlay.hide()
	AudioManager.play_battle_bgm()
	BattleManager.retry_battle()

func _update_element_indicator(unit) -> void:
	var idx: int = _party_index_of(unit)
	if idx < 0 or idx >= GameManager.equipment.size():
		return
	var weapon = GameManager.equipment[idx].get("weapon")
	var elem: String = ""
	if weapon != null and "weapon_element" in weapon:
		elem = weapon.weapon_element
	if elem == "":
		_attack_btn.text = "Attack"
		return
	var icon: String
	match elem:
		"fire":      icon = "🔥"
		"ice":       icon = "❄️"
		"lightning": icon = "⚡"
		_:           icon = ""
	_attack_btn.text = "Attack %s" % icon

func _on_ng_plus_pressed() -> void:
	GameManager.new_game()
	GameManager.ng_plus_unlocked = true
	GameManager.ng_plus_mode = true
	SaveSystem.save(0)
	GameManager.change_scene("res://scenes/world/WorldMap.tscn")

func _on_gameover_menu_pressed() -> void:
	GameManager.change_scene("res://scenes/ui/MainMenu.tscn")

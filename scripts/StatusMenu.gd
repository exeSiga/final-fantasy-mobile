extends CanvasLayer

@onready var _content: VBoxContainer = $BG/Panel/VBox/Scroll/Content

func _ready() -> void:
	$BG/Panel/VBox/CloseBtn.pressed.connect(queue_free)
	_build()

func _build() -> void:
	for c in _content.get_children():
		c.queue_free()
	for i in GameManager.party.size():
		_build_member_section(i)

func _build_member_section(idx: int) -> void:
	var m = GameManager.party[idx]
	var sec := VBoxContainer.new()
	sec.add_theme_constant_override("separation", 4)
	# Header
	var header := Label.new()
	header.text = "%s  —  %s  Lv.%d" % [m.unit_name, m.character_class, m.level]
	header.add_theme_font_size_override("font_size", 32)
	header.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1))
	sec.add_child(header)
	# XP bar row
	var xp_lbl := Label.new()
	xp_lbl.text = "XP: %d / %d" % [m.xp, m.xp_to_next_level]
	xp_lbl.add_theme_font_size_override("font_size", 24)
	xp_lbl.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0, 1))
	sec.add_child(xp_lbl)
	# Stats row
	var stats_lbl := Label.new()
	stats_lbl.text = "HP: %d/%d    MP: %d/%d" % [m.hp, m.max_hp, m.mp, m.max_mp]
	stats_lbl.add_theme_font_size_override("font_size", 26)
	sec.add_child(stats_lbl)
	var combat_lbl := Label.new()
	combat_lbl.text = "ATK: %d    DEF: %d    SPD: %d" % [m.atk, m.def, m.spd]
	combat_lbl.add_theme_font_size_override("font_size", 26)
	sec.add_child(combat_lbl)
	# Equipment
	var w_item = GameManager.equipment[idx].get("weapon")
	var a_item = GameManager.equipment[idx].get("armor")
	var equip_txt := "[W] %s    [A] %s" % [
		w_item.equip_name if w_item != null else "—",
		a_item.equip_name if a_item != null else "—"
	]
	var equip_lbl := Label.new()
	equip_lbl.text = equip_txt
	equip_lbl.add_theme_font_size_override("font_size", 24)
	equip_lbl.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6, 1))
	sec.add_child(equip_lbl)
	# Status
	if m.status != "":
		var status_lbl := Label.new()
		status_lbl.text = "Status: %s" % m.status.to_upper()
		status_lbl.add_theme_font_size_override("font_size", 24)
		status_lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4, 1))
		sec.add_child(status_lbl)
	var sep := HSeparator.new()
	sep.custom_minimum_size = Vector2(0, 12)
	sec.add_child(sep)
	_content.add_child(sec)

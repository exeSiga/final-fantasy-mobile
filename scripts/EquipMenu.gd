extends CanvasLayer

@onready var _content: VBoxContainer = $BG/Panel/VBox/Scroll/Content

var _select_member_idx: int = -1
var _select_slot: String = ""

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
	sec.add_theme_constant_override("separation", 6)
	var header := Label.new()
	header.text = "%s  (%s)  Lv.%d   ATK:%d  DEF:%d" % [
		m.unit_name, m.character_class, m.level, m.atk, m.def
	]
	header.add_theme_font_size_override("font_size", 28)
	header.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1))
	sec.add_child(header)
	_add_slot_row(sec, idx, "weapon", "[W]")
	_add_slot_row(sec, idx, "armor",  "[A]")
	var sep := HSeparator.new()
	sep.custom_minimum_size = Vector2(0, 10)
	sec.add_child(sep)
	_content.add_child(sec)

func _add_slot_row(parent: Node, member_idx: int, slot_name: String, prefix: String) -> void:
	var row := HBoxContainer.new()
	var equip = GameManager.equipment[member_idx].get(slot_name)
	var lbl := Label.new()
	if equip != null:
		var stat: String = "ATK" if equip.slot == 0 else "DEF"
		lbl.text = "%s %s  [+%d %s]" % [prefix, equip.equip_name, equip.stat_bonus, stat]
	else:
		lbl.text = "%s —" % prefix
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 26)
	row.add_child(lbl)
	if equip != null:
		var rm_btn := Button.new()
		rm_btn.text = "Remove"
		rm_btn.add_theme_font_size_override("font_size", 24)
		rm_btn.custom_minimum_size = Vector2(150, 60)
		rm_btn.pressed.connect(_on_unequip.bind(member_idx, slot_name))
		row.add_child(rm_btn)
	if _has_equippable(member_idx, slot_name):
		var eq_btn := Button.new()
		eq_btn.text = "Equip"
		eq_btn.add_theme_font_size_override("font_size", 24)
		eq_btn.custom_minimum_size = Vector2(120, 60)
		eq_btn.pressed.connect(_on_open_select.bind(member_idx, slot_name))
		row.add_child(eq_btn)
	parent.add_child(row)

func _has_equippable(member_idx: int, slot_name: String) -> bool:
	var m = GameManager.party[member_idx]
	var want_slot: int = 0 if slot_name == "weapon" else 1
	for key in GameManager.equip_inventory:
		if GameManager.equip_inventory[key] <= 0:
			continue
		var item = load(key)
		if item == null or item.slot != want_slot:
			continue
		if item.allowed_classes.size() > 0 and not item.allowed_classes.has(m.character_class):
			continue
		return true
	return false

func _on_unequip(member_idx: int, slot_name: String) -> void:
	GameManager.unequip_slot(member_idx, slot_name)
	_build()

func _on_open_select(member_idx: int, slot_name: String) -> void:
	_select_member_idx = member_idx
	_select_slot = slot_name
	_show_select_list()

func _show_select_list() -> void:
	for c in _content.get_children():
		c.queue_free()
	var m = GameManager.party[_select_member_idx]
	var want_slot: int = 0 if _select_slot == "weapon" else 1
	var title := Label.new()
	title.text = "Select for %s (%s):" % [m.unit_name, m.character_class]
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1))
	_content.add_child(title)
	var found := false
	for key in GameManager.equip_inventory:
		if GameManager.equip_inventory[key] <= 0:
			continue
		var item = load(key)
		if item == null or item.slot != want_slot:
			continue
		if item.allowed_classes.size() > 0 and not item.allowed_classes.has(m.character_class):
			continue
		found = true
		var row := HBoxContainer.new()
		var stat: String = "ATK" if item.slot == 0 else "DEF"
		var lbl := Label.new()
		lbl.text = "%s  [+%d %s]  ×%d" % [item.equip_name, item.stat_bonus, stat, GameManager.equip_inventory[key]]
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.add_theme_font_size_override("font_size", 26)
		row.add_child(lbl)
		var sel_btn := Button.new()
		sel_btn.text = "Select"
		sel_btn.add_theme_font_size_override("font_size", 24)
		sel_btn.custom_minimum_size = Vector2(140, 60)
		sel_btn.pressed.connect(_on_item_selected.bind(item))
		row.add_child(sel_btn)
		_content.add_child(row)
	if not found:
		var none_lbl := Label.new()
		none_lbl.text = "No compatible equipment in inventory."
		none_lbl.add_theme_font_size_override("font_size", 26)
		_content.add_child(none_lbl)
	var back := Button.new()
	back.text = "Back"
	back.add_theme_font_size_override("font_size", 26)
	back.custom_minimum_size = Vector2(0, 70)
	back.pressed.connect(_build)
	_content.add_child(back)

func _on_item_selected(item: Resource) -> void:
	GameManager.equip(_select_member_idx, item)
	_build()

extends Control

@onready var content: VBoxContainer = $Panel/ScrollContainer/Content
@onready var close_btn: Button = $Panel/CloseButton
@onready var status_lbl: Label = $Panel/StatusLabel

var _pending_member: int = -1
var _pending_slot_name: String = ""
var _pending_slot_idx: int = -1

func _ready() -> void:
	close_btn.pressed.connect(_on_close)
	_build()

func _build() -> void:
	for c in content.get_children():
		c.queue_free()
	for i in GameManager.party.size():
		var member = GameManager.party[i]
		_add_header("%s's Materia" % member.unit_name)
		for slot_name in ["weapon", "armor"]:
			var item = GameManager.equipment[i].get(slot_name)
			if item == null:
				continue
			var slots: int = item.materia_slots if "materia_slots" in item else 0
			var item_label: String = item.equip_name if "equip_name" in item else slot_name
			for s in range(slots):
				var key: String = "%d_%s_%d" % [i, slot_name, s]
				var mat_path: String = GameManager.materia_equipped.get(key, "")
				var slot_text: String = "[Empty]"
				if mat_path != "":
					var mat = load(mat_path)
					if mat != null:
						slot_text = mat.materia_name
						var thresholds: Array = GameManager.MATERIA_AP_THRESHOLDS.get(mat_path, [])
						if not thresholds.is_empty():
							var ap: int = GameManager.materia_ap.get(mat_path, 0)
							var lvl: int = GameManager.get_materia_level(mat_path)
							if lvl >= 3:
								slot_text += " [Lv3 MAX]"
							else:
								var next_ap: int = thresholds[lvl - 1]
								slot_text += " [Lv%d %d/%d AP]" % [lvl, ap, next_ap]
				_add_slot_row(i, slot_name, s, "%s slot %d: %s" % [item_label, s + 1, slot_text], mat_path != "")

func _add_header(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 26)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
	content.add_child(lbl)

func _add_slot_row(member_idx: int, slot_name: String, slot_idx: int, label: String, has_materia: bool) -> void:
	var row := HBoxContainer.new()
	var lbl := Label.new()
	lbl.text = label
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 22)
	row.add_child(lbl)
	if has_materia:
		var remove_btn := Button.new()
		remove_btn.text = "Remove"
		remove_btn.add_theme_font_size_override("font_size", 20)
		remove_btn.pressed.connect(_on_remove.bind(member_idx, slot_name, slot_idx))
		row.add_child(remove_btn)
	else:
		var equip_btn := Button.new()
		equip_btn.text = "Equip"
		equip_btn.add_theme_font_size_override("font_size", 20)
		equip_btn.pressed.connect(_on_equip_pick.bind(member_idx, slot_name, slot_idx))
		row.add_child(equip_btn)
	content.add_child(row)

func _on_equip_pick(member_idx: int, slot_name: String, slot_idx: int) -> void:
	_pending_member = member_idx
	_pending_slot_name = slot_name
	_pending_slot_idx = slot_idx
	for c in content.get_children():
		c.queue_free()
	_add_header("Choose Materia:")
	if GameManager.materia_inventory.is_empty():
		var lbl := Label.new()
		lbl.text = "No materia in inventory. Buy from Shop!"
		lbl.add_theme_font_size_override("font_size", 22)
		content.add_child(lbl)
		return
	for mat_path in GameManager.materia_inventory:
		var count: int = GameManager.materia_inventory[mat_path]
		if count <= 0:
			continue
		var mat = load(mat_path)
		if mat == null:
			continue
		var btn := Button.new()
		btn.text = "%s (x%d) — %s" % [mat.materia_name, count, mat.description]
		btn.add_theme_font_size_override("font_size", 22)
		btn.pressed.connect(_on_materia_selected.bind(mat_path))
		content.add_child(btn)

func _on_materia_selected(mat_path: String) -> void:
	GameManager.equip_materia(_pending_member, _pending_slot_name, _pending_slot_idx, mat_path)
	status_lbl.text = "Materia equipped!"
	_build()

func _on_remove(member_idx: int, slot_name: String, slot_idx: int) -> void:
	GameManager.unequip_materia(member_idx, slot_name, slot_idx)
	status_lbl.text = "Materia removed."
	_build()

func _on_close() -> void:
	queue_free()

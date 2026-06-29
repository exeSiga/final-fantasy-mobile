extends CanvasLayer

signal closed

func _ready() -> void:
	layer = 45
	_build()

func _build() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 40.0
	panel.offset_right = -40.0
	panel.offset_top = 80.0
	panel.offset_bottom = -80.0
	add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	panel.add_child(vbox)
	var title := Label.new()
	title.text = "Quêtes"
	title.add_theme_font_size_override("font_size", 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	for q in QuestManager.QUESTS:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 20)
		var done: bool = QuestManager.completed.get(q.quest_id, false)
		var kills: int = QuestManager.progress(q.quest_id)
		var info := Label.new()
		var status: String = "✅" if done else "🔄 %d/%d" % [kills, q.target_count]
		info.text = "[%s] %s\n%s" % [status, q.quest_name, q.description]
		info.add_theme_font_size_override("font_size", 26)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.autowrap_mode = TextServer.AUTOWRAP_WORD
		hbox.add_child(info)
		var reward_lbl := Label.new()
		var rtext: String = ""
		if q.reward_gold > 0:
			rtext = "+%dG" % q.reward_gold
		elif q.reward_xp > 0:
			rtext = "+%d XP" % q.reward_xp
		elif q.reward_item_path != "":
			rtext = "Équipement"
		reward_lbl.text = rtext
		reward_lbl.add_theme_font_size_override("font_size", 26)
		reward_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2, 1))
		hbox.add_child(reward_lbl)
		vbox.add_child(hbox)
	var close_btn := Button.new()
	close_btn.text = "Fermer"
	close_btn.add_theme_font_size_override("font_size", 36)
	close_btn.custom_minimum_size = Vector2(0, 90)
	close_btn.pressed.connect(func(): closed.emit(); queue_free())
	vbox.add_child(close_btn)

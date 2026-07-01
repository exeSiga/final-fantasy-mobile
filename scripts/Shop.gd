extends Control

const SHOP_ITEMS: Array[String] = [
	"res://resources/items/potion.tres",
	"res://resources/items/hi_potion.tres",
	"res://resources/items/ether.tres",
	"res://resources/items/phoenix_down.tres",
]

const SHOP_SUMMONS: Array[String] = [
	"res://resources/materias/summon_ifrit.tres",
	"res://resources/materias/summon_shiva.tres",
	"res://resources/materias/summon_ramuh.tres",
	"res://resources/materias/summon_bahamut.tres",
]

const SHOP_MATERIAS: Array[String] = [
	"res://resources/materias/fire_materia.tres",
	"res://resources/materias/thunder_materia.tres",
	"res://resources/materias/blizzard_materia.tres",
	"res://resources/materias/cure_materia.tres",
	"res://resources/materias/hp_plus_materia.tres",
	"res://resources/materias/mp_plus_materia.tres",
	"res://resources/materias/enemy_skill_materia.tres",
]

const SHINRA_ARMORY: Array[String] = [
	"res://resources/equipment/shinra_blade.tres",
	"res://resources/equipment/shinra_armor.tres",
]

const RANK_2ND_EQUIP: Array[String] = [
	"res://resources/equipment/mithril_sword.tres",
	"res://resources/equipment/guard_bangle.tres",
]
const RANK_2ND_MATERIAS: Array[String] = [
	"res://resources/materias/thundara_materia.tres",
]
const RANK_1ST_EQUIP: Array[String] = [
	"res://resources/equipment/hardedge.tres",
	"res://resources/equipment/wizard_rod.tres",
]
const RANK_1ST_MATERIAS: Array[String] = [
	"res://resources/materias/regen_materia.tres",
]

const SHOP_EQUIP: Array[String] = [
	"res://resources/equipment/short_sword.tres",
	"res://resources/equipment/long_sword.tres",
	"res://resources/equipment/mage_staff.tres",
	"res://resources/equipment/dark_staff.tres",
	"res://resources/equipment/leather_armor.tres",
	"res://resources/equipment/chain_mail.tres",
	"res://resources/equipment/silk_robe.tres",
	"res://resources/equipment/flame_blade.tres",
	"res://resources/equipment/ice_brand.tres",
	"res://resources/equipment/thunder_blade.tres",
]

@onready var gold_label: Label = $Panel/VBox/GoldLabel
@onready var item_list: VBoxContainer = $Panel/VBox/ItemList
@onready var status_label: Label = $Panel/VBox/StatusLabel

var _craft_scene: PackedScene = preload("res://scenes/ui/CraftMenu.tscn")

func _ready() -> void:
	$Panel/VBox/CloseButton.pressed.connect(_on_close)
	_build_shop()

func _build_shop() -> void:
	gold_label.text = "Gold: %d" % GameManager.gold
	for child in item_list.get_children():
		child.queue_free()
	# --- Craft Workshop button ---
	_add_craft_button()
	# --- Items section ---
	_add_section_header("Items")
	for path in SHOP_ITEMS:
		var item = load(path)
		_add_item_row(item.item_name, item.price, _on_buy.bind(item))
	# --- Equipment section ---
	_add_section_header("Weapons & Armor")
	for path in SHOP_EQUIP:
		var item = load(path)
		var bonus_stat: String = "ATK" if item.slot == 0 else "DEF"
		var elem_icon: String = _element_icon(item.get("weapon_element", ""))
		var lbl_extra: String = " [+%d %s%s]" % [item.stat_bonus, bonus_stat, elem_icon]
		_add_item_row(item.equip_name + lbl_extra, item.price, _on_buy_equip.bind(item))
	# --- Materia section ---
	_add_section_header("⚡ Materia")
	for path in SHOP_MATERIAS:
		var mat = load(path)
		_add_item_row(mat.materia_name + " — " + mat.description, mat.price, _on_buy_materia.bind(mat))
	# --- Summon Materia section ---
	_add_section_header("★ Summon Materia")
	for path in SHOP_SUMMONS:
		var mat = load(path)
		_add_item_row(mat.materia_name + " — " + mat.description, mat.price, _on_buy_materia.bind(mat))
	# --- ShinRa Armory (2nd Class and above only) ---
	if GameManager.get_soldier_rank() != "3rd Class":
		_add_section_header("ShinRa Armory [%s]" % GameManager.get_soldier_rank())
		for path in SHINRA_ARMORY:
			var item = load(path)
			var bonus_stat: String = "ATK" if item.slot == 0 else "DEF"
			var lbl_extra: String = " [+%d %s]" % [item.stat_bonus, bonus_stat]
			_add_item_row(item.equip_name + lbl_extra, item.price, _on_buy_equip.bind(item))
	# --- 2nd Class Arsenal ---
	var rank: String = GameManager.get_soldier_rank()
	var prev_rank: String = GameManager.shop_last_rank
	if rank == "2nd Class" or rank == "1st Class":
		var new_2nd: bool = (prev_rank == "3rd Class")
		_add_section_header("★ Arsenal 2nd Class" + (" [NOUVEAU]" if new_2nd else ""))
		for path in RANK_2ND_EQUIP:
			var item = load(path)
			var bonus_stat: String = "ATK" if item.slot == 0 else "DEF"
			_add_item_row(item.equip_name + " [+%d %s]" % [item.stat_bonus, bonus_stat], item.price, _on_buy_equip.bind(item), new_2nd)
		for path in RANK_2ND_MATERIAS:
			var mat = load(path)
			_add_item_row(mat.materia_name + " — " + mat.description, mat.price, _on_buy_materia.bind(mat), new_2nd)
	if rank == "1st Class":
		var new_1st: bool = (prev_rank != "1st Class")
		_add_section_header("★ Arsenal 1st Class" + (" [NOUVEAU]" if new_1st else ""))
		for path in RANK_1ST_EQUIP:
			var item = load(path)
			var bonus_stat: String = "ATK" if item.slot == 0 else "DEF"
			_add_item_row(item.equip_name + " [+%d %s]" % [item.stat_bonus, bonus_stat], item.price, _on_buy_equip.bind(item), new_1st)
		for path in RANK_1ST_MATERIAS:
			var mat = load(path)
			_add_item_row(mat.materia_name + " — " + mat.description, mat.price, _on_buy_materia.bind(mat), new_1st)
	GameManager.shop_last_rank = rank

func _add_craft_button() -> void:
	var btn := Button.new()
	btn.text = "Open Craft Workshop"
	btn.add_theme_font_size_override("font_size", 28)
	btn.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6, 1))
	btn.custom_minimum_size = Vector2(0, 70)
	btn.pressed.connect(_on_craft_pressed)
	item_list.add_child(btn)

func _on_craft_pressed() -> void:
	var menu = _craft_scene.instantiate()
	get_parent().add_child(menu)

func _add_section_header(title: String) -> void:
	var lbl := Label.new()
	lbl.text = "— %s —" % title
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 26)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1))
	item_list.add_child(lbl)

func _add_item_row(label_text: String, price: int, callback: Callable, is_new: bool = false) -> void:
	var row := HBoxContainer.new()
	var lbl := Label.new()
	var display_price: int = GameManager.get_discounted_price(price)
	var price_text: String = "%dG" % display_price if display_price == price else "%dG (-%d%%)" % [display_price, int((1.0 - GameManager.merchant_discount) * 100)]
	lbl.text = "%s — %s" % [label_text, price_text]
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 26)
	if is_new:
		lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1))
	var btn := Button.new()
	btn.text = "Buy"
	btn.add_theme_font_size_override("font_size", 26)
	btn.custom_minimum_size = Vector2(110, 56)
	btn.pressed.connect(callback)
	row.add_child(lbl)
	row.add_child(btn)
	item_list.add_child(row)

func _on_buy(item) -> void:
	if GameManager.buy_item(item):
		status_label.text = "Bought %s!" % item.item_name
		gold_label.text = "Gold: %d" % GameManager.gold
	else:
		status_label.text = "Not enough gold!"
	await get_tree().create_timer(1.2).timeout
	status_label.text = ""

func _on_buy_equip(item) -> void:
	if GameManager.buy_equipment(item):
		status_label.text = "Bought %s! (equip via menu)" % item.equip_name
		gold_label.text = "Gold: %d" % GameManager.gold
	else:
		status_label.text = "Not enough gold!"
	await get_tree().create_timer(1.2).timeout
	status_label.text = ""

func _on_buy_materia(mat) -> void:
	if GameManager.buy_materia(mat):
		status_label.text = "Bought %s!" % mat.materia_name
		gold_label.text = "Gold: %d" % GameManager.gold
	else:
		status_label.text = "Not enough gold!"
	await get_tree().create_timer(1.2).timeout
	status_label.text = ""
	await get_tree().create_timer(1.5).timeout
	status_label.text = ""

func _element_icon(element: String) -> String:
	match element:
		"fire":      return " 🔥"
		"ice":       return " ❄️"
		"lightning": return " ⚡"
	return ""

func _on_close() -> void:
	queue_free()

extends Control

const SHOP_ITEMS: Array[String] = [
	"res://resources/items/potion.tres",
	"res://resources/items/hi_potion.tres",
	"res://resources/items/ether.tres",
	"res://resources/items/phoenix_down.tres",
]

@onready var gold_label: Label = $Panel/VBox/GoldLabel
@onready var item_list: VBoxContainer = $Panel/VBox/ItemList
@onready var status_label: Label = $Panel/VBox/StatusLabel

func _ready() -> void:
	$Panel/VBox/CloseButton.pressed.connect(_on_close)
	_build_shop()

func _build_shop() -> void:
	gold_label.text = "Gold: %d" % GameManager.gold
	for child in item_list.get_children():
		child.queue_free()
	for path in SHOP_ITEMS:
		var item: Item = load(path)
		var row := HBoxContainer.new()
		var lbl := Label.new()
		lbl.text = "%s — %dG" % [item.item_name, item.price]
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.theme_override_font_sizes = {"font_size": 28}
		var btn := Button.new()
		btn.text = "Buy"
		btn.theme_override_font_sizes = {"font_size": 28}
		btn.custom_minimum_size = Vector2(120, 60)
		btn.pressed.connect(_on_buy.bind(item))
		row.add_child(lbl)
		row.add_child(btn)
		item_list.add_child(row)

func _on_buy(item: Item) -> void:
	if GameManager.buy_item(item):
		status_label.text = "Bought %s!" % item.item_name
		gold_label.text = "Gold: %d" % GameManager.gold
	else:
		status_label.text = "Not enough gold!"
	await get_tree().create_timer(1.2).timeout
	status_label.text = ""

func _on_close() -> void:
	queue_free()

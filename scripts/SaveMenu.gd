extends Control

const SLOT_COUNT := 3

@onready var slot_container: VBoxContainer = $VBox/SlotContainer
@onready var back_button: Button = $VBox/BackButton

var _mode: String = "save"

func init(mode: String) -> void:
	_mode = mode

func _ready() -> void:
	back_button.pressed.connect(_on_back)
	_build_slots()

func _build_slots() -> void:
	for child in slot_container.get_children():
		child.queue_free()
	for i in SLOT_COUNT:
		var info: Dictionary = SaveSystem.get_slot_info(i)
		var btn: Button = Button.new()
		if info.is_empty():
			btn.text = "Slot %d — Empty" % (i + 1)
		else:
			btn.text = "Slot %d  Lv.%d  %s" % [i + 1, info.get("level", 1), info.get("timestamp", "")]
		btn.custom_minimum_size = Vector2(0, 100)
		btn.theme_override_font_sizes = {"font_size": 30}
		btn.pressed.connect(_on_slot_pressed.bind(i))
		slot_container.add_child(btn)

func _on_slot_pressed(slot: int) -> void:
	if _mode == "save":
		SaveSystem.save(slot)
		_build_slots()
	else:
		if SaveSystem.load_save(slot):
			GameManager.change_scene("res://scenes/world/WorldMap.tscn")

func _on_back() -> void:
	GameManager.change_scene("res://scenes/ui/MainMenu.tscn")

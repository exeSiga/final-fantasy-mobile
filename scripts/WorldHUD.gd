extends CanvasLayer

@onready var level_label: Label = $Panel/HBox/LevelLabel
@onready var gold_label: Label = $Panel/HBox/GoldLabel

func _ready() -> void:
	GameManager.gold_changed.connect(_on_gold_changed)
	GameManager.level_up.connect(_on_level_up)
	_refresh()

func _refresh() -> void:
	if not GameManager.party.is_empty():
		level_label.text = "Lv.%d" % GameManager.party[0].level
	elif GameManager.player_unit:
		level_label.text = "Lv.%d" % GameManager.player_unit.level
	gold_label.text = "Gold: %d" % GameManager.gold

func _on_gold_changed(_amount: int) -> void:
	_refresh()

func _on_level_up(_new_level: int) -> void:
	_refresh()

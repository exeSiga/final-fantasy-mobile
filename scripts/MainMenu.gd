extends Control

func _ready() -> void:
	GameManager.set_state(GameManager.GameState.MAIN_MENU)
	$VBox/NewGameButton.pressed.connect(_on_new_game)

func _on_new_game() -> void:
	GameManager.change_scene("res://scenes/world/WorldMap.tscn")

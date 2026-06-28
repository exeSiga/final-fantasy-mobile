extends Control

func _ready() -> void:
	GameManager.set_state(GameManager.GameState.MAIN_MENU)
	$VBox/NewGameButton.pressed.connect(_on_new_game)
	$VBox/LoadGameButton.pressed.connect(_on_load_game)
	$VBox/SettingsButton.pressed.connect(func():
		AudioManager.play_sfx_button()
		GameManager.change_scene("res://scenes/ui/SettingsMenu.tscn")
	)

func _on_new_game() -> void:
	AudioManager.play_sfx_button()
	GameManager.new_game()
	GameManager.change_scene("res://scenes/world/WorldMap.tscn")

func _on_load_game() -> void:
	AudioManager.play_sfx_button()
	GameManager.change_scene("res://scenes/ui/SaveMenu.tscn")

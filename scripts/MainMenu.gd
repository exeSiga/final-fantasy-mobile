extends Control

func _ready() -> void:
	GameManager.set_state(GameManager.GameState.MAIN_MENU)
	$VBox/NewGameButton.pressed.connect(_on_new_game)
	$VBox/LoadGameButton.pressed.connect(_on_load_game)
	$VBox/SettingsButton.pressed.connect(func():
		AudioManager.play_sfx_button()
		GameManager.change_scene("res://scenes/ui/SettingsMenu.tscn")
	)
	_animate_stars()
	_animate_title()

func _on_new_game() -> void:
	AudioManager.play_sfx_button()
	GameManager.new_game()
	GameManager.change_scene("res://scenes/world/WorldMap.tscn")

func _on_load_game() -> void:
	AudioManager.play_sfx_button()
	GameManager.change_scene("res://scenes/ui/SaveMenu.tscn")

func _animate_stars() -> void:
	for i in 8:
		var star := Label.new()
		star.text = "*"
		var sz: int = randi() % 20 + 20
		star.add_theme_font_size_override("font_size", sz)
		star.add_theme_color_override("font_color", Color(1.0, 1.0, 0.8, 1.0))
		star.position = Vector2(randf() * 1080.0, randf() * 1920.0)
		add_child(star)
		var tw := create_tween()
		tw.set_loops()
		tw.tween_interval(randf() * 1.5)
		tw.tween_property(star, "modulate:a", 0.05, 0.6 + randf() * 1.2)
		tw.tween_property(star, "modulate:a", 1.0, 0.6 + randf() * 1.2)

func _animate_title() -> void:
	var lbl := Label.new()
	lbl.text = "FINAL FANTASY"
	lbl.add_theme_font_size_override("font_size", 72)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3, 0.18))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.size = Vector2(1080, 100)
	lbl.position = Vector2(0, 1920)
	add_child(lbl)
	var tw := create_tween()
	tw.set_loops()
	tw.tween_property(lbl, "position:y", -120.0, 14.0)
	tw.tween_interval(0.5)
	tw.tween_property(lbl, "position:y", 1920.0, 0.01)

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
	_setup_particles()
	_animate_buttons_in()

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

func _setup_particles() -> void:
	var particles := CPUParticles2D.new()
	particles.amount = 45
	particles.lifetime = 5.0
	particles.explosiveness = 0.0
	particles.randomness = 1.0
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(540, 960)
	particles.position = Vector2(540, 960)
	particles.direction = Vector2(0.0, -1.0)
	particles.spread = 55.0
	particles.gravity = Vector2(0.0, -4.0)
	particles.initial_velocity_min = 15.0
	particles.initial_velocity_max = 75.0
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 5.0
	var grad := Gradient.new()
	grad.colors = PackedColorArray([
		Color(0.20, 0.60, 1.00, 0.90),
		Color(0.80, 0.70, 0.20, 0.55),
		Color(0.50, 0.20, 1.00, 0.00)
	])
	grad.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	particles.color_ramp = grad
	add_child(particles)

func _animate_buttons_in() -> void:
	var buttons := [$VBox/NewGameButton, $VBox/LoadGameButton, $VBox/SettingsButton]
	for i in buttons.size():
		var btn = buttons[i]
		btn.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_interval(0.35 + i * 0.18)
		tw.tween_property(btn, "modulate:a", 1.0, 0.45).set_ease(Tween.EASE_OUT)

extends Control

func _ready() -> void:
	$VBox/BGMSlider.value = AudioManager.bgm_volume
	$VBox/SFXSlider.value = AudioManager.sfx_volume
	$VBox/BGMSlider.value_changed.connect(func(v): AudioManager.set_bgm_volume(v))
	$VBox/SFXSlider.value_changed.connect(func(v): AudioManager.set_sfx_volume(v))
	$VBox/BackButton.pressed.connect(func(): GameManager.change_scene("res://scenes/ui/MainMenu.tscn"))

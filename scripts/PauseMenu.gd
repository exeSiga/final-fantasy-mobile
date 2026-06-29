extends CanvasLayer

func show_pause() -> void:
	visible = true
	get_tree().paused = true

func _on_resume_pressed() -> void:
	get_tree().paused = false
	visible = false

func _on_save_quit_pressed() -> void:
	get_tree().paused = false
	SaveSystem.save(0)
	GameManager.change_scene("res://scenes/ui/MainMenu.tscn")

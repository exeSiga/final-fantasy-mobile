extends CanvasLayer

const FADE_TIME := 0.35

var _overlay: ColorRect

func _ready() -> void:
	layer = 100
	_overlay = ColorRect.new()
	_overlay.anchor_right = 1.0
	_overlay.anchor_bottom = 1.0
	_overlay.color = Color(0, 0, 0, 0)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)

func fade_to(path: String) -> void:
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var t := create_tween()
	t.tween_property(_overlay, "color:a", 1.0, FADE_TIME)
	await t.finished
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	t = create_tween()
	t.tween_property(_overlay, "color:a", 0.0, FADE_TIME)
	await t.finished
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

extends CanvasLayer

const FADE_TIME := 0.35

var _overlay: ColorRect
var _is_fading: bool = false
var _pending_path: String = ""

func _ready() -> void:
	layer = 100
	_overlay = ColorRect.new()
	_overlay.anchor_right = 1.0
	_overlay.anchor_bottom = 1.0
	_overlay.color = Color(0, 0, 0, 0)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)

func fade_to(path: String) -> void:
	# Deux appels concurrents (ex: un déclencheur qui arrive pendant qu'une transition précédente
	# n'a pas fini son fade-out) faisaient tourner deux coroutines en même temps sur le même
	# _overlay et sur change_scene_to_file, se marchant dessus. Un appel pendant qu'une transition
	# est déjà en cours retient la destination et l'enchaîne dès que la transition en cours se
	# termine — jamais abandonné en silence, sinon le jeu resterait bloqué sur l'ancienne scène.
	if _is_fading:
		_pending_path = path
		return
	_is_fading = true
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
	_is_fading = false
	if _pending_path != "":
		var next_path := _pending_path
		_pending_path = ""
		fade_to(next_path)

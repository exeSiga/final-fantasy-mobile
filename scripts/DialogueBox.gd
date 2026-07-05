extends CanvasLayer

signal next_pressed

@onready var _panel: PanelContainer = $Panel
@onready var _portrait: ColorRect = $Panel/HBox/Portrait
@onready var _label: Label = $Panel/HBox/VBox/DialogueLabel
@onready var _next_btn: Button = $Panel/HBox/VBox/NextButton

var _full_text: String = ""
var _displayed_chars: int = 0
var _typewriter_timer: Timer = null

func _ready() -> void:
	layer = 50
	_next_btn.text = "▶"
	_next_btn.pressed.connect(_on_next_pressed)
	_portrait.color = Color(0.04, 0.04, 0.20, 1)
	_typewriter_timer = Timer.new()
	_typewriter_timer.wait_time = 0.03
	_typewriter_timer.timeout.connect(_advance_typewriter)
	add_child(_typewriter_timer)
	_add_corner_decorations()

func _add_corner_decorations() -> void:
	var vp_size := get_viewport().get_visible_rect().size
	var panel_top_y := vp_size.y + _panel.offset_top
	var positions := [
		Vector2(8.0, panel_top_y + 4.0),
		Vector2(vp_size.x - 34.0, panel_top_y + 4.0),
		Vector2(8.0, vp_size.y - 34.0),
		Vector2(vp_size.x - 34.0, vp_size.y - 34.0)
	]
	for pos in positions:
		var lbl := Label.new()
		lbl.text = "✦"
		lbl.add_theme_font_size_override("font_size", 22)
		lbl.add_theme_color_override("font_color", Color(0.78, 0.65, 0.15, 1))
		lbl.position = pos
		add_child(lbl)

func show_line(text: String) -> void:
	_full_text = text
	_displayed_chars = 0
	_label.text = ""
	_typewriter_timer.start()

func _advance_typewriter() -> void:
	if _displayed_chars < _full_text.length():
		_displayed_chars += 1
		_label.text = _full_text.substr(0, _displayed_chars)
	else:
		_typewriter_timer.stop()

func _on_next_pressed() -> void:
	if _displayed_chars < _full_text.length():
		_typewriter_timer.stop()
		_displayed_chars = _full_text.length()
		_label.text = _full_text
	else:
		next_pressed.emit()

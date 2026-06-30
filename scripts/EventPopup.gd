extends CanvasLayer

signal confirmed
signal closed

@onready var _icon: ColorRect = $Panel/VBox/Icon
@onready var _message: Label = $Panel/VBox/Message
@onready var _confirm_btn: Button = $Panel/VBox/ConfirmBtn
@onready var _close_btn: Button = $Panel/VBox/CloseBtn

func _ready() -> void:
	_confirm_btn.pressed.connect(_on_confirmed)
	_close_btn.pressed.connect(_on_closed)

func setup(icon_color: Color, message: String, btn_label: String, show_close: bool = false) -> void:
	_icon.color = icon_color
	_message.text = message
	_confirm_btn.text = btn_label
	_confirm_btn.add_theme_font_size_override("font_size", 30)
	_message.add_theme_font_size_override("font_size", 26)
	_close_btn.visible = show_close

func _on_confirmed() -> void:
	confirmed.emit()
	queue_free()

func _on_closed() -> void:
	closed.emit()
	queue_free()

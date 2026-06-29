extends CanvasLayer

signal next_pressed

@onready var _panel: PanelContainer = $Panel
@onready var _portrait: ColorRect = $Panel/HBox/Portrait
@onready var _label: Label = $Panel/HBox/VBox/DialogueLabel
@onready var _next_btn: Button = $Panel/HBox/VBox/NextButton

func _ready() -> void:
	_next_btn.pressed.connect(func(): next_pressed.emit())
	layer = 50

func show_line(text: String) -> void:
	_label.text = text

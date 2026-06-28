extends Control
class_name VirtualJoystick

signal input_vector(vec: Vector2)

const DEAD_ZONE := 20.0
const RADIUS := 100.0

@onready var _base: ColorRect = $Base
@onready var _knob: ColorRect = $Base/Knob

var _touch_index: int = -1
var _center: Vector2 = Vector2.ZERO
var _current_vec: Vector2 = Vector2.ZERO

func _ready() -> void:
	_center = _base.size / 2.0

func get_vector() -> Vector2:
	return _current_vec

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1 and _is_in_zone(event.position):
			_touch_index = event.index
			_center = event.position - global_position
		elif not event.pressed and event.index == _touch_index:
			_touch_index = -1
			_current_vec = Vector2.ZERO
			_knob.position = _base.size / 2.0 - _knob.size / 2.0
			input_vector.emit(Vector2.ZERO)
	elif event is InputEventScreenDrag and event.index == _touch_index:
		var local: Vector2 = event.position - global_position - _center
		var clamped: Vector2 = local.limit_length(RADIUS)
		_knob.position = _base.size / 2.0 - _knob.size / 2.0 + clamped
		_current_vec = clamped / RADIUS if local.length() > DEAD_ZONE else Vector2.ZERO
		input_vector.emit(_current_vec)

func _is_in_zone(pos: Vector2) -> bool:
	var local: Vector2 = pos - global_position
	return local.x >= 0 and local.y >= 0 and local.x <= size.x and local.y <= size.y

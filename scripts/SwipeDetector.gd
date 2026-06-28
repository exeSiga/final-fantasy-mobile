extends Node

signal swiped(direction: String)

const MIN_DISTANCE := 80.0

var _start_pos: Vector2 = Vector2.ZERO
var _tracking: bool = false

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_start_pos = event.position
			_tracking = true
		elif _tracking:
			_tracking = false
			var delta: Vector2 = event.position - _start_pos
			if delta.length() < MIN_DISTANCE:
				return
			if abs(delta.x) > abs(delta.y):
				swiped.emit("right" if delta.x > 0 else "left")
			else:
				swiped.emit("down" if delta.y > 0 else "up")

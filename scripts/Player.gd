extends CharacterBody2D

const SPEED := 400.0
const STEPS_PER_ENCOUNTER := 80

signal encounter_triggered

var _step_counter: int = 0
var _facing: String = "down"
var _joystick_vec: Vector2 = Vector2.ZERO

func set_joystick_input(vec: Vector2) -> void:
	_joystick_vec = vec

func _physics_process(_delta: float) -> void:
	var kb_dir := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	var dir := kb_dir if kb_dir.length() > 0.1 else _joystick_vec

	if dir.length() > 0.1:
		dir = dir.normalized()
		_update_facing(dir)
		velocity = dir * SPEED
		_step_counter += 1
		if _step_counter >= STEPS_PER_ENCOUNTER:
			_step_counter = 0
			encounter_triggered.emit()
	else:
		velocity = Vector2.ZERO

	move_and_slide()

func _update_facing(dir: Vector2) -> void:
	if abs(dir.x) > abs(dir.y):
		_facing = "right" if dir.x > 0 else "left"
	else:
		_facing = "down" if dir.y > 0 else "up"

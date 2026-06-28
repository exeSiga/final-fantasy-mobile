extends ProgressBar
class_name HPBar

func _ready() -> void:
	show_percentage = false
	min_value = 0.0

func set_unit(unit: CombatUnit) -> void:
	max_value = unit.max_hp
	value = unit.hp

func animate_to(new_hp: int) -> void:
	var tween := create_tween()
	tween.tween_property(self, "value", float(new_hp), 0.4).set_ease(Tween.EASE_OUT)
	if new_hp / max_value < 0.25:
		tween.parallel().tween_property(self, "modulate", Color(1, 0.2, 0.2, 1), 0.2)
	else:
		tween.parallel().tween_property(self, "modulate", Color(1, 1, 1, 1), 0.2)

extends Node2D

var sprite_color: Color = Color(0.5, 0.5, 0.5)
var unit_name_label: String = ""
var active_highlight: bool = false
var _flash_active: bool = false
var _flash_color: Color = Color.WHITE

const W := 160.0
const H := 200.0

func setup(color: Color, unit_name: String) -> void:
	sprite_color = color
	unit_name_label = unit_name
	queue_redraw()

func set_active(active: bool) -> void:
	active_highlight = active
	queue_redraw()

func flash(color: Color) -> void:
	_flash_color = color
	_flash_active = true
	queue_redraw()
	await get_tree().create_timer(0.18).timeout
	_flash_active = false
	queue_redraw()

func _draw() -> void:
	if active_highlight:
		draw_rect(Rect2(-W*0.50, -H*0.55, W*1.00, H*1.10), Color(1,1,0.4,0.12))
	match unit_name_label:
		"Warrior":
			_draw_warrior()
		"Black Mage":
			_draw_black_mage()
		"White Mage":
			_draw_white_mage()
		"Slime":
			_draw_slime()
		"Goblin":
			_draw_goblin()
		"Skeleton":
			_draw_skeleton()
		"Bat":
			_draw_bat()
		"Dark Knight":
			_draw_dark_knight()
		"Orc":
			_draw_orc()
		"Shadow":
			_draw_shadow()
		"Troll":
			_draw_troll()
		"Gargoyle":
			_draw_gargoyle()
		_:
			draw_rect(Rect2(-W*0.40, -H*0.50, W*0.80, H*1.00), sprite_color)
	if _flash_active:
		draw_rect(Rect2(-W*0.50, -H*0.55, W*1.00, H*1.10), Color(_flash_color.r, _flash_color.g, _flash_color.b, 0.65))

func _draw_warrior() -> void:
	var c := sprite_color
	draw_rect(Rect2(-W*0.30, h(0.12), W*0.22, H*0.30), c.darkened(0.25))
	draw_rect(Rect2(W*0.08,  h(0.12), W*0.22, H*0.30), c.darkened(0.25))
	draw_rect(Rect2(-W*0.40, h(-0.28), W*0.80, H*0.42), c)
	draw_polygon(
		PackedVector2Array([Vector2(-W*0.40,h(-0.28)), Vector2(-W*0.55,h(0.44)), Vector2(-W*0.28,h(0.10))]),
		PackedColorArray([c.darkened(0.35)]))
	draw_rect(Rect2(-W*0.24, h(-0.68), W*0.48, H*0.42), c.lightened(0.20))
	draw_rect(Rect2(-W*0.24, h(-0.50), W*0.48, H*0.12), Color(0.92, 0.92, 1.0, 0.95))

func _draw_black_mage() -> void:
	var c := sprite_color
	var hat_c := c.darkened(0.1)
	# Robe body (wide trapezoid look via rects)
	draw_rect(Rect2(-W*0.32, h(-0.10), W*0.64, H*0.55), c.darkened(0.05))
	draw_rect(Rect2(-W*0.42, h(0.22), W*0.84, H*0.22), c.darkened(0.10))
	# Belt
	draw_rect(Rect2(-W*0.32, h(0.10), W*0.64, H*0.08), Color(0.6, 0.4, 0.0, 1))
	# Hat brim
	draw_rect(Rect2(-W*0.40, h(-0.22), W*0.80, H*0.10), hat_c.lightened(0.05))
	# Pointy hat (triangle)
	draw_polygon(
		PackedVector2Array([Vector2(0, h(-0.72)), Vector2(-W*0.28, h(-0.18)), Vector2(W*0.28, h(-0.18))]),
		PackedColorArray([hat_c]))
	# Face (black void under brim)
	draw_circle(Vector2(0, h(-0.30)), W*0.18, Color(0.05, 0.02, 0.08, 1))
	# Glowing yellow eyes
	draw_circle(Vector2(-W*0.10, h(-0.32)), W*0.07, Color(1.0, 0.92, 0.1, 1))
	draw_circle(Vector2( W*0.10, h(-0.32)), W*0.07, Color(1.0, 0.92, 0.1, 1))
	# Staff (right side)
	draw_rect(Rect2(W*0.32, h(-0.60), W*0.10, H*0.90), Color(0.5, 0.3, 0.1, 1))
	draw_circle(Vector2(W*0.37, h(-0.62)), W*0.14, Color(0.7, 0.2, 0.9, 1))
	draw_circle(Vector2(W*0.37, h(-0.62)), W*0.08, Color(0.95, 0.6, 1.0, 1))

func _draw_white_mage() -> void:
	var c := sprite_color
	# Robe (wide, A-line)
	draw_polygon(
		PackedVector2Array([Vector2(-W*0.24, h(-0.10)), Vector2(W*0.24, h(-0.10)),
							Vector2(W*0.44, h(0.45)),  Vector2(-W*0.44, h(0.45))]),
		PackedColorArray([c.lightened(0.05)]))
	# Cross emblem on robe
	draw_rect(Rect2(-W*0.06, h(0.06), W*0.12, H*0.24), Color(0.85, 0.15, 0.15, 1))
	draw_rect(Rect2(-W*0.14, h(0.12), W*0.28, H*0.08), Color(0.85, 0.15, 0.15, 1))
	# Hood (rounded)
	draw_circle(Vector2(0, h(-0.30)), W*0.30, c.lightened(0.15))
	# Face inside hood
	draw_circle(Vector2(0, h(-0.30)), W*0.20, Color(0.98, 0.88, 0.78, 1))
	# Eyes (gentle, closed look)
	draw_rect(Rect2(-W*0.12, h(-0.34), W*0.08, H*0.03), Color(0.3, 0.2, 0.1, 1))
	draw_rect(Rect2( W*0.04, h(-0.34), W*0.08, H*0.03), Color(0.3, 0.2, 0.1, 1))
	# Staff (left side, golden)
	draw_rect(Rect2(-W*0.42, h(-0.58), W*0.10, H*0.88), Color(0.7, 0.55, 0.1, 1))
	draw_circle(Vector2(-W*0.37, h(-0.60)), W*0.14, Color(0.9, 0.75, 0.1, 1))
	draw_circle(Vector2(-W*0.37, h(-0.60)), W*0.07, Color(1.0, 1.0, 0.9, 1))

func _draw_slime() -> void:
	var c := sprite_color
	draw_polygon(
		PackedVector2Array([
			Vector2(-W*0.48, h(0.30)), Vector2( W*0.48, h(0.30)),
			Vector2( W*0.42, h(0.05)), Vector2( W*0.26, h(-0.14)),
			Vector2(0, h(-0.22)),      Vector2(-W*0.26, h(-0.14)),
			Vector2(-W*0.42, h(0.05))]),
		PackedColorArray([c]))
	draw_rect(Rect2(-W*0.48, h(0.18), W*0.96, H*0.20), c)
	draw_circle(Vector2(-W*0.14, h(-0.02)), W*0.10, Color.WHITE)
	draw_circle(Vector2( W*0.14, h(-0.02)), W*0.10, Color.WHITE)
	draw_circle(Vector2(-W*0.12, h( 0.00)), W*0.06, Color(0.1, 0.1, 0.1))
	draw_circle(Vector2( W*0.16, h( 0.00)), W*0.06, Color(0.1, 0.1, 0.1))

func _draw_goblin() -> void:
	var c := sprite_color
	draw_rect(Rect2(-W*0.28, h(-0.14), W*0.56, H*0.46), c)
	draw_rect(Rect2(-W*0.28, h(0.32), W*0.20, H*0.22), c.darkened(0.2))
	draw_rect(Rect2( W*0.08, h(0.32), W*0.20, H*0.22), c.darkened(0.2))
	draw_circle(Vector2(0, h(-0.38)), W*0.28, c.lightened(0.12))
	draw_polygon(
		PackedVector2Array([Vector2(-W*0.32, h(-0.28)), Vector2(-W*0.42, h(-0.56)), Vector2(-W*0.20, h(-0.28))]),
		PackedColorArray([c.lightened(0.12)]))
	draw_polygon(
		PackedVector2Array([Vector2( W*0.32, h(-0.28)), Vector2( W*0.42, h(-0.56)), Vector2( W*0.20, h(-0.28))]),
		PackedColorArray([c.lightened(0.12)]))
	draw_circle(Vector2(-W*0.12, h(-0.40)), W*0.08, Color(1.0, 0.9, 0.0))
	draw_circle(Vector2( W*0.12, h(-0.40)), W*0.08, Color(1.0, 0.9, 0.0))

func _draw_skeleton() -> void:
	var c := sprite_color
	draw_circle(Vector2(0, h(-0.46)), W*0.28, c)
	draw_circle(Vector2(-W*0.12, h(-0.50)), W*0.09, Color(0.05, 0.05, 0.05))
	draw_circle(Vector2( W*0.12, h(-0.50)), W*0.09, Color(0.05, 0.05, 0.05))
	draw_rect(Rect2(-W*0.18, h(-0.28), W*0.36, H*0.10), c)
	draw_rect(Rect2(-W*0.06, h(-0.18), W*0.12, H*0.38), c)
	draw_rect(Rect2(-W*0.30, h(-0.10), W*0.60, H*0.08), c)
	draw_rect(Rect2(-W*0.30, h( 0.02), W*0.60, H*0.08), c)
	draw_rect(Rect2(-W*0.30, h( 0.14), W*0.60, H*0.08), c)
	draw_rect(Rect2(-W*0.20, h(0.22), W*0.16, H*0.22), c)
	draw_rect(Rect2( W*0.04, h(0.22), W*0.16, H*0.22), c)

func _draw_bat() -> void:
	var c := sprite_color
	draw_polygon(
		PackedVector2Array([Vector2(0,0), Vector2(-W*0.60, h(-0.38)), Vector2(-W*0.60, h(0.38))]),
		PackedColorArray([c]))
	draw_polygon(
		PackedVector2Array([Vector2(0,0), Vector2( W*0.60, h(-0.38)), Vector2( W*0.60, h(0.38))]),
		PackedColorArray([c]))
	draw_circle(Vector2(0, 0), W*0.22, c.lightened(0.15))
	draw_circle(Vector2(-W*0.10, h(-0.04)), W*0.07, Color(1.0, 0.1, 0.1))
	draw_circle(Vector2( W*0.10, h(-0.04)), W*0.07, Color(1.0, 0.1, 0.1))

func _draw_dark_knight() -> void:
	var c := sprite_color
	draw_rect(Rect2(-W*0.32, h(0.10), W*0.26, H*0.34), c.darkened(0.35))
	draw_rect(Rect2( W*0.06, h(0.10), W*0.26, H*0.34), c.darkened(0.35))
	draw_rect(Rect2(-W*0.40, h(-0.30), W*0.80, H*0.42), c)
	draw_rect(Rect2(-W*0.56, h(-0.38), W*0.24, H*0.24), Color(0.72, 0.05, 0.05))
	draw_rect(Rect2( W*0.32, h(-0.38), W*0.24, H*0.24), Color(0.72, 0.05, 0.05))
	draw_rect(Rect2(-W*0.28, h(-0.72), W*0.56, H*0.44), c)
	draw_rect(Rect2(-W*0.22, h(-0.56), W*0.44, H*0.12), Color(0.92, 0.08, 0.08, 0.95))

func _draw_orc() -> void:
	var c := sprite_color
	draw_rect(Rect2(-W*0.34, h(0.08), W*0.24, H*0.36), c.darkened(0.3))
	draw_rect(Rect2( W*0.10, h(0.08), W*0.24, H*0.36), c.darkened(0.3))
	draw_rect(Rect2(-W*0.44, h(-0.32), W*0.88, H*0.44), c)
	draw_circle(Vector2(0, h(-0.50)), W*0.30, c.lightened(0.10))
	draw_circle(Vector2(-W*0.12, h(-0.52)), W*0.07, Color(1.0, 0.6, 0.1))
	draw_circle(Vector2( W*0.12, h(-0.52)), W*0.07, Color(1.0, 0.6, 0.1))
	draw_polygon(
		PackedVector2Array([Vector2(-W*0.10, h(-0.38)), Vector2(-W*0.16, h(-0.26)), Vector2(0, h(-0.30))]),
		PackedColorArray([Color(0.8, 0.9, 0.8)]))

func _draw_shadow() -> void:
	var c := sprite_color
	draw_rect(Rect2(-W*0.24, h(-0.50), W*0.48, H*0.90), c.darkened(0.1))
	draw_polygon(
		PackedVector2Array([Vector2(-W*0.36, h(-0.38)), Vector2( W*0.36, h(-0.38)), Vector2(0, h(-0.78))]),
		PackedColorArray([c.lightened(0.08)]))
	draw_circle(Vector2(-W*0.10, h(-0.46)), W*0.08, Color(0.9, 0.2, 0.9, 0.9))
	draw_circle(Vector2( W*0.10, h(-0.46)), W*0.08, Color(0.9, 0.2, 0.9, 0.9))

func _draw_troll() -> void:
	var c := sprite_color
	draw_rect(Rect2(-W*0.38, h(0.12), W*0.30, H*0.32), c.darkened(0.2))
	draw_rect(Rect2( W*0.08, h(0.12), W*0.30, H*0.32), c.darkened(0.2))
	draw_rect(Rect2(-W*0.46, h(-0.38), W*0.92, H*0.54), c)
	draw_circle(Vector2(0, h(-0.60)), W*0.36, c.lightened(0.05))
	draw_circle(Vector2(-W*0.14, h(-0.62)), W*0.09, Color(0.9, 0.4, 0.1))
	draw_circle(Vector2( W*0.14, h(-0.62)), W*0.09, Color(0.9, 0.4, 0.1))
	draw_polygon(
		PackedVector2Array([Vector2(-W*0.20, h(-0.40)), Vector2(-W*0.30, h(-0.60)), Vector2(-W*0.08, h(-0.50))]),
		PackedColorArray([c.darkened(0.3)]))
	draw_polygon(
		PackedVector2Array([Vector2( W*0.20, h(-0.40)), Vector2( W*0.30, h(-0.60)), Vector2( W*0.08, h(-0.50))]),
		PackedColorArray([c.darkened(0.3)]))

func _draw_gargoyle() -> void:
	var c := sprite_color
	draw_polygon(
		PackedVector2Array([Vector2(0, h(-0.10)), Vector2(-W*0.60, h(-0.50)), Vector2(-W*0.50, h(0.30))]),
		PackedColorArray([c.darkened(0.1)]))
	draw_polygon(
		PackedVector2Array([Vector2(0, h(-0.10)), Vector2( W*0.60, h(-0.50)), Vector2( W*0.50, h(0.30))]),
		PackedColorArray([c.darkened(0.1)]))
	draw_rect(Rect2(-W*0.24, h(-0.38), W*0.48, H*0.72), c)
	draw_circle(Vector2(0, h(-0.48)), W*0.26, c.lightened(0.12))
	draw_circle(Vector2(-W*0.12, h(-0.52)), W*0.08, Color(0.3, 0.6, 1.0))
	draw_circle(Vector2( W*0.12, h(-0.52)), W*0.08, Color(0.3, 0.6, 1.0))

# Helper: convert fraction of H to absolute Y offset (centered on origin)
func h(frac: float) -> float:
	return H * frac

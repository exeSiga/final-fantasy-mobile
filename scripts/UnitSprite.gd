extends Control

var sprite_color: Color = Color(0.5, 0.5, 0.5)
var unit_name_label: String = ""

func _draw() -> void:
	var w := size.x
	var h := size.y
	if w <= 0.0 or h <= 0.0:
		return
	match unit_name_label:
		"Hero":
			# Legs
			draw_rect(Rect2(w*0.28, h*0.65, w*0.18, h*0.30), sprite_color.darkened(0.25))
			draw_rect(Rect2(w*0.54, h*0.65, w*0.18, h*0.30), sprite_color.darkened(0.25))
			# Body / armor plate
			draw_rect(Rect2(w*0.18, h*0.35, w*0.64, h*0.33), sprite_color)
			# Cape (dark triangle behind body)
			draw_polygon(
				PackedVector2Array([Vector2(w*0.18,h*0.35), Vector2(w*0.05,h*0.90), Vector2(w*0.24,h*0.68)]),
				PackedColorArray([sprite_color.darkened(0.35)]))
			# Head
			draw_rect(Rect2(w*0.30, h*0.08, w*0.40, h*0.30), sprite_color.lightened(0.20))
			# Visor
			draw_rect(Rect2(w*0.30, h*0.22, w*0.40, h*0.10), Color(0.92, 0.92, 1.0, 0.95))
		"Slime":
			# Blob body
			draw_polygon(
				PackedVector2Array([
					Vector2(w*0.10, h*0.78),
					Vector2(w*0.90, h*0.78),
					Vector2(w*0.85, h*0.55),
					Vector2(w*0.72, h*0.38),
					Vector2(w*0.50, h*0.32),
					Vector2(w*0.28, h*0.38),
					Vector2(w*0.15, h*0.55),
				]),
				PackedColorArray([sprite_color]))
			draw_rect(Rect2(w*0.10, h*0.72, w*0.80, h*0.18), sprite_color)
			# Eyes
			draw_circle(Vector2(w*0.38, h*0.56), w*0.07, Color.WHITE)
			draw_circle(Vector2(w*0.62, h*0.56), w*0.07, Color.WHITE)
			draw_circle(Vector2(w*0.40, h*0.57), w*0.04, Color(0.1, 0.1, 0.1))
			draw_circle(Vector2(w*0.64, h*0.57), w*0.04, Color(0.1, 0.1, 0.1))
		"Goblin":
			# Body
			draw_rect(Rect2(w*0.28, h*0.42, w*0.44, h*0.46), sprite_color)
			# Legs
			draw_rect(Rect2(w*0.28, h*0.76, w*0.16, h*0.20), sprite_color.darkened(0.2))
			draw_rect(Rect2(w*0.56, h*0.76, w*0.16, h*0.20), sprite_color.darkened(0.2))
			# Head
			draw_circle(Vector2(w*0.50, h*0.27), w*0.21, sprite_color.lightened(0.12))
			# Pointed ears
			draw_polygon(
				PackedVector2Array([Vector2(w*0.22,h*0.36), Vector2(w*0.30,h*0.14), Vector2(w*0.33,h*0.36)]),
				PackedColorArray([sprite_color.lightened(0.12)]))
			draw_polygon(
				PackedVector2Array([Vector2(w*0.78,h*0.36), Vector2(w*0.70,h*0.14), Vector2(w*0.67,h*0.36)]),
				PackedColorArray([sprite_color.lightened(0.12)]))
			# Eyes
			draw_circle(Vector2(w*0.40, h*0.26), w*0.06, Color(1.0, 0.9, 0.0))
			draw_circle(Vector2(w*0.60, h*0.26), w*0.06, Color(1.0, 0.9, 0.0))
		"Skeleton":
			# Skull
			draw_circle(Vector2(w*0.50, h*0.22), w*0.23, sprite_color)
			# Eye sockets
			draw_circle(Vector2(w*0.38, h*0.20), w*0.08, Color(0.05, 0.05, 0.05))
			draw_circle(Vector2(w*0.62, h*0.20), w*0.08, Color(0.05, 0.05, 0.05))
			# Jaw
			draw_rect(Rect2(w*0.32, h*0.36, w*0.36, h*0.09), sprite_color)
			# Spine
			draw_rect(Rect2(w*0.46, h*0.44, w*0.08, h*0.36), sprite_color)
			# Ribs
			draw_rect(Rect2(w*0.25, h*0.50, w*0.50, h*0.07), sprite_color)
			draw_rect(Rect2(w*0.25, h*0.62, w*0.50, h*0.07), sprite_color)
			draw_rect(Rect2(w*0.25, h*0.74, w*0.50, h*0.07), sprite_color)
			# Legs
			draw_rect(Rect2(w*0.30, h*0.80, w*0.14, h*0.18), sprite_color)
			draw_rect(Rect2(w*0.56, h*0.80, w*0.14, h*0.18), sprite_color)
		"Bat":
			# Wings
			draw_polygon(
				PackedVector2Array([Vector2(w*0.50,h*0.50), Vector2(w*0.02,h*0.18), Vector2(w*0.02,h*0.82)]),
				PackedColorArray([sprite_color]))
			draw_polygon(
				PackedVector2Array([Vector2(w*0.50,h*0.50), Vector2(w*0.98,h*0.18), Vector2(w*0.98,h*0.82)]),
				PackedColorArray([sprite_color]))
			# Body
			draw_circle(Vector2(w*0.50, h*0.50), w*0.19, sprite_color.lightened(0.15))
			# Eyes
			draw_circle(Vector2(w*0.41, h*0.47), w*0.06, Color(1.0, 0.1, 0.1))
			draw_circle(Vector2(w*0.59, h*0.47), w*0.06, Color(1.0, 0.1, 0.1))
		"DarkKnight":
			# Legs
			draw_rect(Rect2(w*0.22, h*0.68, w*0.22, h*0.30), sprite_color.darkened(0.35))
			draw_rect(Rect2(w*0.56, h*0.68, w*0.22, h*0.30), sprite_color.darkened(0.35))
			# Torso
			draw_rect(Rect2(w*0.18, h*0.35, w*0.64, h*0.36), sprite_color)
			# Pauldrons (red shoulder plates)
			draw_rect(Rect2(w*0.04, h*0.30, w*0.22, h*0.20), Color(0.72, 0.05, 0.05))
			draw_rect(Rect2(w*0.74, h*0.30, w*0.22, h*0.20), Color(0.72, 0.05, 0.05))
			# Helmet
			draw_rect(Rect2(w*0.26, h*0.06, w*0.48, h*0.32), sprite_color)
			# Red visor slit
			draw_rect(Rect2(w*0.30, h*0.22, w*0.40, h*0.09), Color(0.92, 0.08, 0.08, 0.95))
		_:
			draw_rect(Rect2(Vector2.ZERO, size), sprite_color)

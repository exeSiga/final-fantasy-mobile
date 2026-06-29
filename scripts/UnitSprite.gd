## Sprite géométrique pour une unité de combat.
## Extends Node2D — dessiné centré sur l'origine du node.
## Placer le node à la position monde voulue.
extends Node2D

var sprite_color: Color = Color(0.5, 0.5, 0.5)
var unit_name_label: String = ""

const W := 160.0
const H := 200.0

func setup(color: Color, unit_name: String) -> void:
	sprite_color = color
	unit_name_label = unit_name
	queue_redraw()

func _draw() -> void:
	var w := W
	var h := H
	match unit_name_label:
		"Hero":
			# Jambes
			draw_rect(Rect2(-w*0.30, h*0.12, w*0.22, h*0.30), sprite_color.darkened(0.25))
			draw_rect(Rect2(w*0.08,  h*0.12, w*0.22, h*0.30), sprite_color.darkened(0.25))
			# Corps / armure
			draw_rect(Rect2(-w*0.40, -h*0.28, w*0.80, h*0.42), sprite_color)
			# Cape
			draw_polygon(
				PackedVector2Array([Vector2(-w*0.40,-h*0.28), Vector2(-w*0.55,h*0.44), Vector2(-w*0.28,h*0.10)]),
				PackedColorArray([sprite_color.darkened(0.35)]))
			# Tête
			draw_rect(Rect2(-w*0.24, -h*0.68, w*0.48, h*0.42), sprite_color.lightened(0.20))
			# Visière
			draw_rect(Rect2(-w*0.24, -h*0.50, w*0.48, h*0.12), Color(0.92, 0.92, 1.0, 0.95))
		"Slime":
			# Corps blob
			draw_polygon(
				PackedVector2Array([
					Vector2(-w*0.48, h*0.30),
					Vector2( w*0.48, h*0.30),
					Vector2( w*0.42, h*0.05),
					Vector2( w*0.26,-h*0.14),
					Vector2(     0, -h*0.22),
					Vector2(-w*0.26,-h*0.14),
					Vector2(-w*0.42, h*0.05),
				]),
				PackedColorArray([sprite_color]))
			draw_rect(Rect2(-w*0.48, h*0.18, w*0.96, h*0.20), sprite_color)
			# Yeux
			draw_circle(Vector2(-w*0.14, -h*0.02), w*0.10, Color.WHITE)
			draw_circle(Vector2( w*0.14, -h*0.02), w*0.10, Color.WHITE)
			draw_circle(Vector2(-w*0.12,  h*0.00), w*0.06, Color(0.1,0.1,0.1))
			draw_circle(Vector2( w*0.16,  h*0.00), w*0.06, Color(0.1,0.1,0.1))
		"Goblin":
			# Corps
			draw_rect(Rect2(-w*0.28, -h*0.14, w*0.56, h*0.46), sprite_color)
			# Jambes
			draw_rect(Rect2(-w*0.28, h*0.32, w*0.20, h*0.22), sprite_color.darkened(0.2))
			draw_rect(Rect2( w*0.08, h*0.32, w*0.20, h*0.22), sprite_color.darkened(0.2))
			# Tête
			draw_circle(Vector2(0, -h*0.38), w*0.28, sprite_color.lightened(0.12))
			# Oreilles pointues
			draw_polygon(
				PackedVector2Array([Vector2(-w*0.32,-h*0.28), Vector2(-w*0.42,-h*0.56), Vector2(-w*0.20,-h*0.28)]),
				PackedColorArray([sprite_color.lightened(0.12)]))
			draw_polygon(
				PackedVector2Array([Vector2( w*0.32,-h*0.28), Vector2( w*0.42,-h*0.56), Vector2( w*0.20,-h*0.28)]),
				PackedColorArray([sprite_color.lightened(0.12)]))
			# Yeux jaunes
			draw_circle(Vector2(-w*0.12, -h*0.40), w*0.08, Color(1.0,0.9,0.0))
			draw_circle(Vector2( w*0.12, -h*0.40), w*0.08, Color(1.0,0.9,0.0))
		"Skeleton":
			# Crâne
			draw_circle(Vector2(0, -h*0.46), w*0.28, sprite_color)
			# Orbites
			draw_circle(Vector2(-w*0.12, -h*0.50), w*0.09, Color(0.05,0.05,0.05))
			draw_circle(Vector2( w*0.12, -h*0.50), w*0.09, Color(0.05,0.05,0.05))
			# Mâchoire
			draw_rect(Rect2(-w*0.18, -h*0.28, w*0.36, h*0.10), sprite_color)
			# Colonne
			draw_rect(Rect2(-w*0.06, -h*0.18, w*0.12, h*0.38), sprite_color)
			# Côtes
			draw_rect(Rect2(-w*0.30, -h*0.10, w*0.60, h*0.08), sprite_color)
			draw_rect(Rect2(-w*0.30,  h*0.02, w*0.60, h*0.08), sprite_color)
			draw_rect(Rect2(-w*0.30,  h*0.14, w*0.60, h*0.08), sprite_color)
			# Jambes
			draw_rect(Rect2(-w*0.20, h*0.22, w*0.16, h*0.22), sprite_color)
			draw_rect(Rect2( w*0.04, h*0.22, w*0.16, h*0.22), sprite_color)
		"Bat":
			# Ailes (triangles)
			draw_polygon(
				PackedVector2Array([Vector2(0,0), Vector2(-w*0.60,-h*0.38), Vector2(-w*0.60,h*0.38)]),
				PackedColorArray([sprite_color]))
			draw_polygon(
				PackedVector2Array([Vector2(0,0), Vector2( w*0.60,-h*0.38), Vector2( w*0.60,h*0.38)]),
				PackedColorArray([sprite_color]))
			# Corps
			draw_circle(Vector2(0, 0), w*0.22, sprite_color.lightened(0.15))
			# Yeux rouges
			draw_circle(Vector2(-w*0.10, -h*0.04), w*0.07, Color(1.0,0.1,0.1))
			draw_circle(Vector2( w*0.10, -h*0.04), w*0.07, Color(1.0,0.1,0.1))
		"DarkKnight":
			# Jambes
			draw_rect(Rect2(-w*0.32, h*0.10, w*0.26, h*0.34), sprite_color.darkened(0.35))
			draw_rect(Rect2( w*0.06, h*0.10, w*0.26, h*0.34), sprite_color.darkened(0.35))
			# Torse
			draw_rect(Rect2(-w*0.40, -h*0.30, w*0.80, h*0.42), sprite_color)
			# Épaulettes rouges
			draw_rect(Rect2(-w*0.56, -h*0.38, w*0.24, h*0.24), Color(0.72,0.05,0.05))
			draw_rect(Rect2( w*0.32, -h*0.38, w*0.24, h*0.24), Color(0.72,0.05,0.05))
			# Casque
			draw_rect(Rect2(-w*0.28, -h*0.72, w*0.56, h*0.44), sprite_color)
			# Visière rouge
			draw_rect(Rect2(-w*0.22, -h*0.56, w*0.44, h*0.12), Color(0.92,0.08,0.08,0.95))
		_:
			draw_rect(Rect2(-w*0.40, -h*0.50, w*0.80, h*1.00), sprite_color)

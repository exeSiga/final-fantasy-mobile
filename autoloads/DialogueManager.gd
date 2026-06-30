extends Node

signal dialogue_started
signal dialogue_finished

var _box = null
var _lines: Array = []
var _idx: int = 0

const DIALOGUES := {
	"npc_guide": {
		"default": [
			"Bienvenue, aventurier !",
			"Explorez les zones de la WorldMap.",
			"Plus votre niveau est élevé, plus les ennemis sont dangereux.",
		],
		"low_hp": [
			"Vous semblez blessé...",
			"L'auberge peut restaurer vos HP et MP pour 30 or.",
		],
		"high_level": [
			"Impressionnant ! Vous avez atteint un niveau élevé.",
			"Les boss Guard Scorpion et Jenova vous attendent.",
		],
	},
	"npc_soldier": {
		"default": [
			"La ville de Midgar est sous la protection de ShinRa.",
			"Ne causez pas de problèmes ici.",
		],
		"high_level": [
			"Vous êtes fort. Méfiez-vous de Mt. Nibel.",
			"Des monstres inconnus y rôdent depuis peu.",
		],
	},
	"npc_innkeeper": {
		"default": [
			"Bonne nuit ! L'auberge est ouverte.",
			"Reposez-vous, les aventures sont longues.",
		],
		"low_hp": [
			"Vous avez l'air épuisé !",
			"Une nuit de repos vous coûtera 30 or.",
			"Ça vaut le coup non ?",
		],
	},
	"backstory_cloud": [
		"Je m'appelle Cloud. Ex-SOLDIER, 1st Class.",
		"J'ai quitté Midgar après l'incident du réacteur de Nibelheim.",
		"Depuis, je me bats pour ceux qui ne peuvent pas se défendre.",
	],
	"backstory_tifa": [
		"Tifa Lockhart. Je tiens le bar Seventh Heaven, secteur 7.",
		"J'ai grandi à Nibelheim, avec Cloud.",
		"Le bar n'est qu'une façade — en vérité, je me bats contre ShinRa.",
	],
	"backstory_aerith": [
		"Aerith. Je vends des fleurs dans les bas-fonds de Midgar.",
		"On dit que je suis la dernière des Cetra, l'Ancienne race.",
		"La Planète me parle parfois... et elle a peur.",
	],
	"prologue": [
		"Il y a longtemps, ShinRa contrôlait tout...",
		"Mais une résistance grandit dans l'ombre.",
		"Vous êtes l'un de ses membres.",
		"L'aventure commence maintenant.",
	],
}

func show_prologue(parent: Node) -> void:
	show_dialogue(parent, "prologue", "")

func show_npc_dialogue(parent: Node, npc_id: String) -> void:
	var avg_hp_pct: float = _avg_hp_pct()
	var avg_level: int = _avg_level()
	var variant: String = "default"
	if avg_hp_pct < 0.5:
		variant = "low_hp"
	elif avg_level >= 8:
		variant = "high_level"
	show_dialogue(parent, npc_id, variant)

func show_dialogue(parent: Node, npc_id: String, variant: String) -> void:
	if _box != null:
		return
	var entry = DIALOGUES.get(npc_id)
	if entry == null:
		return
	var lines
	if entry is Array:
		lines = entry
	else:
		lines = entry.get(variant, entry.get("default", []))
	if lines.is_empty():
		return
	_lines = lines
	_idx = 0
	var box_scene: PackedScene = load("res://scenes/ui/DialogueBox.tscn")
	_box = box_scene.instantiate()
	parent.add_child(_box)
	_box.next_pressed.connect(_on_next)
	dialogue_started.emit()
	_box.show_line(_lines[_idx])

func _on_next() -> void:
	_idx += 1
	if _idx >= _lines.size():
		_close()
	else:
		_box.show_line(_lines[_idx])

func _close() -> void:
	if _box != null:
		_box.queue_free()
		_box = null
	dialogue_finished.emit()

func is_open() -> bool:
	return _box != null

func _avg_hp_pct() -> float:
	var alive := GameManager.alive_party()
	if alive.is_empty():
		return 1.0
	var total: float = 0.0
	for m in alive:
		total += float(m.hp) / float(m.max_hp)
	return total / alive.size()

func _avg_level() -> int:
	if GameManager.party.is_empty():
		return 1
	var total: int = 0
	for m in GameManager.party:
		total += m.level
	return total / GameManager.party.size()

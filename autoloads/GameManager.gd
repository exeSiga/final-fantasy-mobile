extends Node

enum GameState { MAIN_MENU, WORLD, BATTLE, CUTSCENE, GAME_OVER }

var current_state: GameState = GameState.MAIN_MENU
var current_scene: Node = null

func _ready() -> void:
	get_tree().root.child_entered_tree.connect(_on_root_child_entered)

func _on_root_child_entered(node: Node) -> void:
	current_scene = node

func change_scene(path: String) -> void:
	get_tree().change_scene_to_file(path)

func set_state(new_state: GameState) -> void:
	current_state = new_state

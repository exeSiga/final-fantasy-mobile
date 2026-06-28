extends Node2D

const MAP_WIDTH := 3200.0
const MAP_HEIGHT := 3200.0
const CAMERA_LERP := 5.0

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D
@onready var joystick: VirtualJoystick = $VirtualJoystick

var _shop_scene: PackedScene = preload("res://scenes/ui/Shop.tscn")
var _shop_open: bool = false

func _ready() -> void:
	GameManager.set_state(GameManager.GameState.WORLD)
	AudioManager.play_world_bgm()
	player.encounter_triggered.connect(_on_encounter)
	joystick.input_vector.connect(player.set_joystick_input)
	$DungeonEntrance.body_entered.connect(_on_dungeon_entrance)
	$ShopNPC.body_entered.connect(_on_shop_entered)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = CAMERA_LERP
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(MAP_WIDTH)
	camera.limit_bottom = int(MAP_HEIGHT)
	camera.global_position = player.global_position

func _process(_delta: float) -> void:
	camera.global_position = camera.global_position.lerp(player.global_position, CAMERA_LERP * get_process_delta_time())

func _on_shop_entered(body: Node) -> void:
	if body == player and not _shop_open:
		_shop_open = true
		var shop := _shop_scene.instantiate()
		shop.tree_exited.connect(func(): _shop_open = false)
		get_tree().root.add_child(shop)

func _on_dungeon_entrance(body: Node) -> void:
	if body == player:
		GameManager.change_scene("res://scenes/world/Dungeon.tscn")

func _on_encounter() -> void:
	GameManager.return_after_battle = "res://scenes/world/WorldMap.tscn"
	BattleManager.is_boss_battle = false
	BattleManager.dungeon_mode = false
	GameManager.change_scene("res://scenes/combat/Battle.tscn")

extends Node2D

const ROOM_H := 1600.0
const ROOM_W := 1080.0
const STEPS_PER_ENCOUNTER := 50

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D
@onready var joystick: VirtualJoystick = $VirtualJoystick
@onready var chest_label: Label = $UI/ChestLabel

var _current_room: int = 0
var _boss_done: bool = false
var _step_accum: int = 0
var _chest_opened: Array[bool] = [false, false, false, false]

func _ready() -> void:
	GameManager.set_state(GameManager.GameState.WORLD)
	AudioManager.play_battle_bgm()
	joystick.input_vector.connect(player.set_joystick_input)
	chest_label.text = ""
	camera.limit_left = 0
	camera.limit_top = -int(ROOM_H * 5)
	camera.limit_right = int(ROOM_W)
	camera.limit_bottom = 0
	player.position = Vector2(ROOM_W / 2.0, -50.0)
	camera.position = player.position
	for i in 4:
		var door := get_node_or_null("Rooms/Room%d/Door" % i) as Area2D
		if door:
			door.body_entered.connect(_on_door.bind(i + 1))
	for i in 4:
		var chest := get_node_or_null("Rooms/Room%d/Chest" % i) as Area2D
		if chest:
			chest.body_entered.connect(_on_chest.bind(i))
	var boss_trigger := get_node_or_null("Rooms/Room4/BossTrigger") as Area2D
	if boss_trigger:
		boss_trigger.body_entered.connect(_on_boss_trigger)

func _process(_delta: float) -> void:
	camera.global_position = camera.global_position.lerp(player.global_position, 5.0 * get_process_delta_time())
	_update_room()

func _update_room() -> void:
	var y := player.position.y
	_current_room = clamp(int(-y / ROOM_H), 0, 4)

func _physics_process(_delta: float) -> void:
	if player.velocity.length() > 10:
		_step_accum += 1
		if _step_accum >= STEPS_PER_ENCOUNTER and _current_room < 4:
			_step_accum = 0
			_trigger_dungeon_battle()

func _trigger_dungeon_battle() -> void:
	GameManager.return_after_battle = "res://scenes/world/Dungeon.tscn"
	BattleManager.is_boss_battle = false
	BattleManager._dungeon_mode = true
	GameManager.change_scene("res://scenes/combat/Battle.tscn")

func _on_door(_body: Node, next_room: int) -> void:
	if _body == player:
		player.position = Vector2(ROOM_W / 2.0, -next_room * ROOM_H + ROOM_H - 150.0)

func _on_chest(_body: Node, idx: int) -> void:
	if _body != player or _chest_opened[idx]:
		return
	_chest_opened[idx] = true
	var gold_gain := 30 + idx * 25
	GameManager.add_gold(gold_gain)
	chest_label.text = "+%d Gold!" % gold_gain
	await get_tree().create_timer(1.5).timeout
	chest_label.text = ""

func _on_boss_trigger(_body: Node) -> void:
	if _body == player and not _boss_done:
		_boss_done = true
		GameManager.return_after_battle = "res://scenes/world/WorldMap.tscn"
		BattleManager.is_boss_battle = true
		BattleManager._dungeon_mode = true
		GameManager.change_scene("res://scenes/combat/Battle.tscn")

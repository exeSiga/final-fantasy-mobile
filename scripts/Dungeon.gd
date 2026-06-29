extends Node2D

const ROOM_H := 1600.0
const ROOM_W := 1080.0
const STEPS_PER_ENCOUNTER := 50
const WALL_THICK := 32.0
const DOOR_GAP := 220.0

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D
@onready var joystick: Control = $VirtualJoystick
@onready var chest_label: Label = $UI/ChestLabel

var _current_room: int = 0
var _boss_done: bool = false
var _step_accum: int = 0
var _chest_opened: Array[bool] = [false, false, false, false]

func _ready() -> void:
	GameManager.set_state(GameManager.GameState.WORLD)
	AudioManager.play_world_bgm()
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
	for i in 5:
		var room := get_node_or_null("Rooms/Room%d" % i)
		if room:
			_add_room_walls(room, i)
	if GameManager.dungeon_return_room >= 0:
		var r := GameManager.dungeon_return_room
		GameManager.dungeon_return_room = -1
		_go_to_room(r)

func _go_to_room(room_idx: int) -> void:
	player.position = Vector2(ROOM_W / 2.0, -room_idx * ROOM_H - 150.0)
	camera.position = player.position

func _add_room_walls(room: Node2D, idx: int) -> void:
	var room_top := -(idx + 1) * ROOM_H
	var room_bot := -idx * ROOM_H
	var mid_y := (room_top + room_bot) / 2.0
	# Left wall
	_make_wall(room, Vector2(WALL_THICK / 2.0, mid_y), Vector2(WALL_THICK, ROOM_H))
	# Right wall
	_make_wall(room, Vector2(ROOM_W - WALL_THICK / 2.0, mid_y), Vector2(WALL_THICK, ROOM_H))
	# Bottom wall (closed — one-way progression)
	_make_wall(room, Vector2(ROOM_W / 2.0, room_bot - WALL_THICK / 2.0), Vector2(ROOM_W, WALL_THICK))
	# Top wall: two segments with door gap (rooms 0-3 lead upward; room 4 has solid top)
	var gap_half := DOOR_GAP / 2.0
	var seg_w := ROOM_W / 2.0 - gap_half
	if idx < 4:
		_make_wall(room, Vector2(seg_w / 2.0, room_top + WALL_THICK / 2.0), Vector2(seg_w, WALL_THICK))
		_make_wall(room, Vector2(ROOM_W - seg_w / 2.0, room_top + WALL_THICK / 2.0), Vector2(seg_w, WALL_THICK))
	else:
		_make_wall(room, Vector2(ROOM_W / 2.0, room_top + WALL_THICK / 2.0), Vector2(ROOM_W, WALL_THICK))

func _make_wall(parent: Node2D, pos: Vector2, sz: Vector2) -> void:
	var sb := StaticBody2D.new()
	sb.position = pos
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = sz
	cs.shape = rs
	sb.add_child(cs)
	parent.add_child(sb)

func _process(_delta: float) -> void:
	camera.global_position = camera.global_position.lerp(player.global_position, 5.0 * get_process_delta_time())
	_update_room()

func _update_room() -> void:
	var y: float = player.position.y
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
	BattleManager.dungeon_mode = true
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
	if _body != player or GameManager.dungeon_boss_cleared:
		return
	GameManager.dungeon_boss_cleared = true
	GameManager.dungeon_return_room = _current_room
	GameManager.return_after_battle = "res://scenes/world/Dungeon.tscn"
	BattleManager.is_boss_battle = true
	BattleManager.dungeon_mode = true
	GameManager.change_scene("res://scenes/combat/Battle.tscn")

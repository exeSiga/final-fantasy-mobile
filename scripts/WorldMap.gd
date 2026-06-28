extends Node2D

const MAP_WIDTH := 3200.0
const MAP_HEIGHT := 3200.0
const CAMERA_LERP := 5.0

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D

func _ready() -> void:
	GameManager.set_state(GameManager.GameState.WORLD)
	AudioManager.play_world_bgm()
	player.encounter_triggered.connect(_on_encounter)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = CAMERA_LERP
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(MAP_WIDTH)
	camera.limit_bottom = int(MAP_HEIGHT)
	camera.global_position = player.global_position

func _process(_delta: float) -> void:
	camera.global_position = camera.global_position.lerp(player.global_position, CAMERA_LERP * get_process_delta_time())

func _on_encounter() -> void:
	GameManager.change_scene("res://scenes/combat/Battle.tscn")

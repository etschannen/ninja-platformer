extends Node2D

const PLAYER_SCENE = preload("res://player.tscn")
@onready var level1: = $Level1
@onready var level2: = $Level2
@onready var camera: = $Camera

var player_is_dead = false
@export var roundData = preload("res://global_stats.tres")

func _ready() -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var levelNumber = rng.randi_range(1,10)
	var levelText = "Level"+str(levelNumber)
	camera.offset = get_node(levelText+"/Center").global_position
	
	var player1_guid = Input.get_joy_guid(0)
	var player2_guid = Input.get_joy_guid(1)
	
	RenderingServer.set_default_clear_color("#272736")
	var player1 = PLAYER_SCENE.instantiate()
	var player2 = PLAYER_SCENE.instantiate()
	
	if player1_guid < player2_guid:
		player1.device_id = 0
		player2.device_id = 1
	else:
		player1.device_id = 1
		player2.device_id = 0
	
	get_tree().current_scene.add_child(player1)
	player1.global_position =  get_node(levelText+"/Player1Spawn").global_position
	player1.clothing_color(Color8(8,135,206,255))
	player1.player_id = 0
	
	get_tree().current_scene.add_child(player2)
	player2.global_position = get_node(levelText+"/Player2Spawn").global_position
	player2.clothing_color(Color8(194,11,11,255))
	player1.player_id = 1
	
func _unhandled_input(event):
	if event is InputEventKey && event.keycode == KEY_ESCAPE:
		get_tree().quit()
		
func player_killed():
	if player_is_dead:
		roundData.blue_score -= 1
		roundData.red_score -= 1
		return
	player_is_dead = true
	await get_tree().create_timer(1.0).timeout
	player_is_dead = false
	get_tree().change_scene_to_file("res://Menus/rounds.tscn")

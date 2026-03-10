extends Node2D

const PLAYER_SCENE = preload("res://tag_player.tscn")
const POWERUP_SCENE = preload("res://powerup.tscn")
@onready var level1: = $Level1
@onready var camera: = $Camera
@onready var background: Sprite2D = $Background
@onready var foreground_particles: GPUParticles2D = $ForegroundParticles

var player_is_dead = false

func _ready() -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var levelNumber = 1
	var levelText = "Level"+str(levelNumber)
	camera.offset = get_node(levelText+"/Center").global_position
	background.global_position = get_node(levelText+"/Center").global_position
	foreground_particles.global_position = get_node(levelText+"/Center").global_position
	
	var player1_guid = Input.get_joy_guid(0)
	var player2_guid = Input.get_joy_guid(1)
	
	RenderingServer.set_default_clear_color("#272736")
	var player1A = PLAYER_SCENE.instantiate()
	var player1B = PLAYER_SCENE.instantiate()
	var player2A = PLAYER_SCENE.instantiate()
	var player2B = PLAYER_SCENE.instantiate()
	
	if player1_guid < player2_guid:
		player1A.device_id = 0
		player1B.device_id = 0
		player2A.device_id = 1
		player2B.device_id = 1
	else:
		player1A.device_id = 1
		player1B.device_id = 1
		player2A.device_id = 0
		player2B.device_id = 0
	
	get_tree().current_scene.add_child(player1A)
	player1A.global_position = get_node(levelText+"/Player1ASpawn").global_position
	player1A.clothing_color(Color8(8,105,176,255))
	player1A.player_id = 1
	player1A.character_id = 0
	
	get_tree().current_scene.add_child(player1B)
	player1B.global_position = get_node(levelText+"/Player1BSpawn").global_position
	player1B.clothing_color(Color8(8,105,176,255))
	player1B.player_id = 1
	player1B.character_id = 1
	
	get_tree().current_scene.add_child(player2A)
	player2A.global_position = get_node(levelText+"/Player2ASpawn").global_position
	player2A.clothing_color(Color8(164,11,11,255))
	player2A.player_id = 0
	player2A.character_id = 0
	
	get_tree().current_scene.add_child(player2B)
	player2B.global_position = get_node(levelText+"/Player2BSpawn").global_position
	player2B.clothing_color(Color8(164,11,11,255))
	player2B.player_id = 0
	player2B.character_id = 1
	
func _unhandled_input(event):
	if event is InputEventKey && event.keycode == KEY_ESCAPE:
		get_tree().quit()
		
func player_killed():
	if player_is_dead:
		Globals.roundData.blue_score -= 1
		Globals.roundData.red_score -= 1
		return
	player_is_dead = true
	await get_tree().create_timer(1.0).timeout
	player_is_dead = false
	get_tree().change_scene_to_file("res://Menus/rounds.tscn")

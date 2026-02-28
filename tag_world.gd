extends Node2D

const PLAYER_SCENE = preload("res://tag_player.tscn")
const POWERUP_SCENE = preload("res://powerup.tscn")
@onready var level1: = $Level1
@onready var level2: = $Level2
@onready var camera: = $Camera
@onready var background: Sprite2D = $Background
@onready var foreground_particles: GPUParticles2D = $ForegroundParticles

var player_is_dead = false

func _ready() -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var levelNumber = rng.randi_range(1,10)
	var levelText = "Level"+str(levelNumber)
	camera.offset = get_node(levelText+"/Center").global_position
	background.global_position = get_node(levelText+"/Center").global_position
	foreground_particles.global_position = get_node(levelText+"/Center").global_position
	
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
	player1.global_position = get_node(levelText+"/Player1Spawn").global_position
	player1.clothing_color(Color8(8,105,176,255))
	player1.player_id = 1
	
	get_tree().current_scene.add_child(player2)
	player2.global_position = get_node(levelText+"/Player2Spawn").global_position
	player2.clothing_color(Color8(164,11,11,255))
	player2.player_id = 0
	
	var powerups = range(1,5)
	var durations = [3.5, 5.5, 7.5, 9.5]
	for num in range(0,rng.randi() % 5):
		powerups.remove_at(rng.randi() % powerups.size())
	
	for pow in powerups:
		var powerupType = Globals.PowerupType.NONE
		while powerupType == Globals.PowerupType.NONE:
			powerupType = Globals.PowerupType.values().pick_random()

		var powerup = POWERUP_SCENE.instantiate()
		get_tree().current_scene.add_child(powerup)
		powerup.global_position = get_node(levelText+"/ItemSpawn"+str(pow)).global_position
		powerup.set_powerup_type(powerupType, durations.pick_random())
	
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

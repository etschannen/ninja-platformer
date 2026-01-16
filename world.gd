extends Node2D

const PLAYER_SCENE = preload("res://player.tscn")
const POWERUP_SCENE = preload("res://powerup.tscn")
@onready var level1: = $Level1
@onready var level2: = $Level2
@onready var camera: = $Camera

var player_is_dead = false

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
	player1.global_position = get_node(levelText+"/Player1Spawn").global_position
	player1.clothing_color(Color8(8,135,206,255))
	player1.player_id = 1
	
	get_tree().current_scene.add_child(player2)
	player2.global_position = get_node(levelText+"/Player2Spawn").global_position
	player2.clothing_color(Color8(194,11,11,255))
	player2.player_id = 0
	
	var powerupTypes = Globals.PowerupType.values().duplicate()
	powerupTypes.erase(Globals.PowerupType.NONE)
	
	var powerupNumber1 = rng.randi_range(0,3)
	var powerup1 = POWERUP_SCENE.instantiate()
	
	get_tree().current_scene.add_child(powerup1)
	powerup1.global_position = get_node(levelText+"/ItemSpawn"+str(powerupNumber1+1)).global_position
	powerup1.set_powerup_type(powerupTypes.pick_random())
	powerupTypes.erase(powerup1.hitbox.powerup)
	
	var powerupNumber2 = rng.randi_range(1,3)
	var powerup2 = POWERUP_SCENE.instantiate()
	
	get_tree().current_scene.add_child(powerup2)
	powerup2.global_position = get_node(levelText+"/ItemSpawn"+str((powerupNumber1+powerupNumber2)%4+1)).global_position
	powerup2.set_powerup_type(powerupTypes.pick_random())
	
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

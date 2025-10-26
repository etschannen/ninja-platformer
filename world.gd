extends Node2D

const PLAYER_SCENE = preload("res://player.tscn")
@onready var player_1_spawn: Marker2D = $Player1Spawn
@onready var player_2_spawn: Marker2D = $Player2Spawn

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)
	var player1 = PLAYER_SCENE.instantiate()
	get_tree().current_scene.add_child(player1)
	player1.global_position = player_1_spawn.global_position
	player1.device_id = 0
	player1.clothing_color(Color8(8,135,206,255))
	
	var player2 = PLAYER_SCENE.instantiate()
	get_tree().current_scene.add_child(player2)
	player2.global_position = player_2_spawn.global_position
	player2.device_id = 1
	player2.clothing_color(Color8(194,11,11,255))
	
func _unhandled_input(event):
	if event is InputEventKey && event.keycode == KEY_ESCAPE:
		get_tree().quit()
		
func player_killed():
	await get_tree().create_timer(1.0).timeout
	get_tree().quit()

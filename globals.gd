extends Node
@onready var song_1: AudioStreamPlayer = $Song1

enum PowerupType {
	NONE,
	DASH,
	ATTACK,
	BLOCK,
	MOVEMENT,
	JUMP
}

func _ready():
	await get_tree().create_timer(3.0).timeout
	song_1.play()
	

func get_powerup_color(powerup):
	match powerup:
		Globals.PowerupType.DASH:
			return Color8(20,200,20)
		Globals.PowerupType.ATTACK:
			return Color8(200,20,20)
		Globals.PowerupType.BLOCK:
			return Color8(20,20,200)
		Globals.PowerupType.MOVEMENT:
			return Color8(100,20,100)
		Globals.PowerupType.JUMP:
			return Color8(20,100,100)
		

@export var roundData = preload("res://global_stats.tres")
@export var default_scale = 1.4

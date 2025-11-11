extends Control

@onready var blue_score: Label = $CenterContainer/VBoxContainer/BlueScore
@onready var red_score: Label = $CenterContainer/VBoxContainer/RedScore

@export var roundData = preload("res://global_stats.tres")
@export var run_delay = 1.5


var run_timer = 0.0

func _ready() -> void:
	blue_score.text = "Blue: " + str(roundData.blue_score)
	red_score.text = "Red: " + str(roundData.red_score)
	
func _process(delta: float) -> void:
	run_timer += delta
	if run_timer > run_delay && (Input.is_joy_button_pressed(0, JOY_BUTTON_X) || Input.is_joy_button_pressed(1, JOY_BUTTON_X)):
		if roundData.blue_score >= 5 || roundData.red_score >= 5:
			roundData.blue_score = 0
			roundData.red_score = 0
			get_tree().change_scene_to_file("res://Menus/menu.tscn")
		else:
			get_tree().change_scene_to_file("res://world.tscn")

func _unhandled_input(event):
	if event is InputEventKey && event.keycode == KEY_ESCAPE:
		get_tree().quit()

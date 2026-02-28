extends Control

@export var run_delay = 1.5

var run_timer = 0.0

func _process(delta: float) -> void:
	run_timer += delta
	if run_timer > run_delay && (Input.is_joy_button_pressed(0, JOY_BUTTON_X) || Input.is_joy_button_pressed(1, JOY_BUTTON_X)):
		get_tree().change_scene_to_file("res://tag_world.tscn")

func _unhandled_input(event):
	if event is InputEventKey && event.keycode == KEY_ESCAPE:
		get_tree().quit()

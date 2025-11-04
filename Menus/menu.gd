extends Control

func _process(delta: float) -> void:
	if Input.is_joy_button_pressed(0, JOY_BUTTON_X) || Input.is_joy_button_pressed(1, JOY_BUTTON_X):
		get_tree().change_scene_to_file("res://world.tscn")

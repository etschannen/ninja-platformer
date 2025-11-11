class_name PlayerStats extends Resource

@export var health: = 10 :
	set(value):
		health = value
		if health <= 0: no_health.emit()

signal no_health()

class_name ParticleBurst extends GPUParticles2D

@onready var particles_material: ParticleProcessMaterial = $".".process_material

func _ready() -> void:
	finished.connect(queue_free)
	emitting = true
	explosiveness = 1.0
	one_shot = true
	local_coords = true
	restart()
	
func set_dir(dir):
	particles_material.direction.x = dir.x
	particles_material.direction.y = dir.y

class_name Hitbox extends Area2D

@export var damage: = 1.0
@export var powerup: = Globals.PowerupType.NONE

signal hit(hurtbox: Hurtbox)

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(area_2d: Area2D) -> void:
	process_hit(area_2d)
	
func process_hit(area_2d: Area2D) -> void:
	assert(area_2d is Hurtbox, "The hitbox detected an area that wasn't a hurtbox.")
	var hurtbox = area_2d as Hurtbox
	hurtbox.take_hit(self, false)
	hit.emit(hurtbox)
	
func recheck():
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = $CollisionShape2D.shape
	query.transform = global_transform
	query.collision_mask = collision_mask
	query.collide_with_areas = true

	for obj in space_state.intersect_shape(query):
		process_hit(obj["collider"])

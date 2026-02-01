extends Node2D

@onready var powerup: Node2D = $"."
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Hitbox = $Hitbox
@onready var hurtbox: Hurtbox = $Hurtbox

var spawn_duration = 0.0

func _ready() -> void:
	powerup.scale = Vector2(Globals.default_scale, Globals.default_scale)
	hitbox.body_entered.connect(func(body: Node2D):
		queue_free()
	)
	hitbox.hit.connect(func(other_hurtbox: Hurtbox):
		queue_free()
	)
	hurtbox.hurt.connect(func(other_hitbox: Hitbox):
		pass
	)
	
func _physics_process(delta: float) -> void:
	if spawn_duration > 2.5:
		powerup.visible = false
		spawn_duration -= delta
		queue_redraw()
	elif spawn_duration > 0.0:
		powerup.visible = true
		spawn_duration -= delta
		queue_redraw()
	elif spawn_duration < 0.0:
		powerup.visible = true
		spawn_duration = 0.0
		animated_sprite_2d.material.set_shader_parameter("alpha", 1.0)
		hitbox.set_collision_mask_value(1,true)
		hitbox.set_collision_mask_value(4,true)
		hurtbox.set_collision_layer_value(5,true)
		hitbox.recheck()

func set_powerup_type(powerup, duration):
	hitbox.powerup = powerup
	spawn_duration = duration
	animated_sprite_2d.material.set_shader_parameter("hat_end_color", Globals.get_powerup_color(powerup))
	if spawn_duration >= 0:
		animated_sprite_2d.material.set_shader_parameter("alpha", 0.5)
		hitbox.set_collision_mask_value(1,false)
		hitbox.set_collision_mask_value(4,false)
		hurtbox.set_collision_layer_value(5,false)

func _draw() -> void:
	if spawn_duration > 0.0: 
		draw_arc(Vector2(0,1), 7, 0, 2*spawn_duration/2.5*PI, 30, Color8(0,255,0,127), 2)

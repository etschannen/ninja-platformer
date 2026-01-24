extends Node2D

@onready var powerup: Node2D = $"."
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Hitbox = $Hitbox
@onready var hurtbox: Hurtbox = $Hurtbox

var spawn_duration = 0.0
var full_spawn_duration = 0.0
var timer_color = Color8(0,0,0)

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
	if spawn_duration > 0.0:
		spawn_duration -= delta
		queue_redraw()
	elif spawn_duration < 0.0:
		spawn_duration = 0.0
		animated_sprite_2d.material.set_shader_parameter("alpha", 1.0)
		hitbox.set_collision_mask_value(1,true)
		hitbox.set_collision_mask_value(4,true)
		hurtbox.set_collision_layer_value(5,true)
		hitbox.recheck()

func set_powerup_type(powerup, duration):
	hitbox.powerup = powerup
	spawn_duration = duration
	full_spawn_duration = spawn_duration
	animated_sprite_2d.material.set_shader_parameter("hat_end_color", Globals.get_powerup_color(powerup))
	if spawn_duration >= 0:
		animated_sprite_2d.material.set_shader_parameter("alpha", 0.5)
		hitbox.set_collision_mask_value(1,false)
		hitbox.set_collision_mask_value(4,false)
		hurtbox.set_collision_layer_value(5,false)
		if spawn_duration <= 3.0:
			timer_color = Color8(0,255,0,127)
		elif spawn_duration <= 6.0:
			timer_color = Color8(255,255,0,127)
		else:
			timer_color = Color8(255,0,0,127)

func _draw() -> void:
	if spawn_duration > 0.0: 
		draw_arc(Vector2(0,1), 7, 0, 2*spawn_duration/full_spawn_duration*PI, 30, timer_color, 2)

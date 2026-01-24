extends Node2D

@onready var powerup: Node2D = $"."
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Hitbox = $Hitbox
@onready var hurtbox: Hurtbox = $Hurtbox

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

func set_powerup_type(powerup):
	hitbox.powerup = powerup
	animated_sprite_2d.material.set_shader_parameter("hat_end_color", Globals.get_powerup_color(powerup))

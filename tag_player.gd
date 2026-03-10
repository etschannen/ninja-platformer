extends CharacterBody2D

const PLAYER_SCENE = preload("res://tag_player.tscn")
const SPARK_PARTICLE_BURST_EFFECT = preload("res://sparks_particle_burst_effect.tscn")

enum STATE { CLIMB, HIT, DEAD }

@export var stats: PlayerStats
@export var state: = STATE.CLIMB

@export var max_speed: = 180
@export var acceleration: = 10000
@export var friction: = 10000
@export var device_id: = 0
@export var player_id: = 0
@export var character_id: = 0
@export var player_color: = Color8(255,255,255,255)
@export var hat_color: = Color8(0,0,0,255)
@export var border_color: = Color8(0,255,0,255)
@export var transparent_color: = Color8(0,0,0,0)
@export var dash_amt_start: = 500
@export var dash_amt_finish: = 180
@export var dash_time: = 0.10
@export var dash_stop_time: = 0.04
@export var dash_cooldown: = 0.5
@export var attack_rebound_time: = 0.4
@export var attack_cooldown: = 0.6
@export var max_stretch = 0.2
@export var stretch_full_duration = 0.25
@export var stretch_duration = 0.2
@export var max_stamina = 0.75
@export var stamina_idle_time = 1.5
@export var stamina_recharge_ratio = 0.2

var is_dashing: = false
var dash_timer: = 0.0
var dash_cooldown_timer: = 0.0
var dash_velocity = Vector2(0,0)
var velocity_before_dash = Vector2(0,0)
var screen_size = Rect2(0,0,1,1)
var attack_hold_timer = 0.0
var attack_cooldown_timer = 0.0
var is_ghost = false
var ghost_timer = 0.0
var blood_timer = 0.0
var current_stretch = 0
var current_stretch_time = 0.0
var dim_time = 0.0
var dim_duration = 2.0
var dim_max = 3.0
var dim_min = 2.0
var current_stamina = max_stamina
var stamina_idle_duration = stamina_idle_time
var using_stamina = false

@onready var player: CharacterBody2D = $"."
@onready var anchor: Node2D = $Anchor
@onready var sprite_upper: Sprite2D = $Anchor/SpriteUpper
@onready var sprite_lower: Sprite2D = $Anchor/SpriteLower
@onready var animation_player_upper: AnimationPlayer = $AnimationPlayerUpper
@onready var animation_player_lower: AnimationPlayer = $AnimationPlayerLower
@onready var effects_animation_player: AnimationPlayer = $EffectsAnimationPlayer
@onready var hurtbox: Hurtbox = $Anchor/Hurtbox
@onready var hitbox: Hitbox = $Anchor/Hitbox
@onready var shaker_upper: = Shaker.new(sprite_upper)
@onready var shaker_lower: = Shaker.new(sprite_lower)
@onready var jump_sound: AudioStreamPlayer = $JumpSound
@onready var dash_sound: AudioStreamPlayer = $DashSound
@onready var hit_hurt_sound: AudioStreamPlayer = $HitHurtSound
@onready var slash_sound: AudioStreamPlayer = $SlashSound
@onready var dash_particles: GPUParticles2D = $DashParticles
@onready var dash_particles_material: ParticleProcessMaterial = $DashParticles.process_material
@onready var blood_particles: GPUParticles2D = $BloodParticles
@onready var blood_particles_material: ParticleProcessMaterial = $BloodParticles.process_material
@onready var hat: Sprite2D = $Anchor/Hat
@onready var point_light: PointLight2D = $Anchor/PointLight2D

func clothing_color(color):
	player_color = color
	sprite_upper.material.set_shader_parameter("primary_color", player_color)
	sprite_upper.material.set_shader_parameter("secondary_color", player_color.darkened(0.2))
	sprite_upper.material.set_shader_parameter("border_color", transparent_color)
	
func update_hat_color(color):
	if hat.visible:
		hat_color = hat_color + color
	else:
		hat.visible = true
		hat_color = color
	sprite_upper.material.set_shader_parameter("hat_color", hat_color)

func _ready() -> void:
	var viewport_size = get_viewport_rect().size
	var top_left = get_viewport().canvas_transform.affine_inverse()*Vector2(0,0)
	var bottom_right = get_viewport().canvas_transform.affine_inverse()*viewport_size
	screen_size = Rect2(top_left, bottom_right-top_left)
	
	sprite_lower.material.set_shader_parameter("flash_color", Color("ff4d4d"))
	
	animation_player_lower.current_animation_changed.connect(func(animation_name: String):
		if animation_player_upper.current_animation.begins_with("attack") || stats.health <= 0: return
		animation_player_upper.play(animation_name)
	)
	
	animation_player_upper.animation_finished.connect(func(animation_name: String):
		if !animation_name.begins_with("attack"): return
		animation_player_upper.play(animation_player_lower.current_animation)
		animation_player_upper.seek(animation_player_lower.current_animation_position)
	)
	
	if is_ghost:
		remove_collision()
	
	hurtbox.hurt.connect(func(other_hitbox: Hitbox, _stomp):
		if other_hitbox.powerup != Globals.PowerupType.NONE:
			update_hat_color(Globals.get_powerup_color(other_hitbox.powerup))
		
		match other_hitbox.powerup:
			Globals.PowerupType.DASH:
				dash_time += 0.1
				return
			Globals.PowerupType.ATTACK:
				attack_cooldown -= 0.15
				return
			Globals.PowerupType.BLOCK:
				attack_rebound_time += 0.4
				return
			Globals.PowerupType.MOVEMENT:
				max_speed += 100
				return
		
		if hitbox.collison_number() > 2:
			remove_collision()
			
			state = STATE.DEAD
			animation_player_upper.play("dead")
			if player_id == 0:
				Globals.roundData.blue_score += 1
			else:
				Globals.roundData.red_score += 1
			get_tree().current_scene.player_killed()
	)

func update_dash_velocity():
	if dash_timer < dash_stop_time:
		velocity = Vector2(0,0)
	else:
		var dash_move_time = dash_timer-dash_stop_time
		velocity = dash_velocity*(dash_amt_start*dash_move_time/dash_time+dash_amt_finish*(dash_time-dash_move_time)/dash_time)

#func _input(event):
#	if event is InputEventJoypadMotion && abs(event.axis_value) > 0.2:
#		print("Axis: ", event.axis, "Value: ", event.axis_value, "Device: ", event.device)
#	if event is InputEventJoypadButton:
#		print("Button: ", event.button_index, "Pressed: ", event.pressed, "Device: ", event.device)

func remove_collision():
	hurtbox.set_collision_layer_value(4,false)
	hitbox.set_collision_mask_value(4,false)
	player.set_collision_layer_value(6, false)
	player.set_collision_mask_value(6, false)
	sprite_upper.z_index = 1
	sprite_lower.z_index = 0

func add_ghost():
	var ghost = PLAYER_SCENE.instantiate()
	ghost.device_id = device_id
	ghost.player_id = player_id
	ghost.global_position = global_position
	ghost.is_ghost = true
	get_tree().current_scene.add_child(ghost)
	ghost.clothing_color(player_color)
	ghost.animation_player_upper.play(animation_player_upper.current_animation)
	ghost.animation_player_upper.seek(animation_player_upper.current_animation_position)
	ghost.animation_player_upper.pause()
	ghost.animation_player_lower.play(animation_player_lower.current_animation)
	ghost.animation_player_lower.seek(animation_player_lower.current_animation_position)
	ghost.animation_player_lower.pause()
	ghost.player.scale = player.scale
	ghost.anchor.scale = anchor.scale
	ghost.point_light.visible = false
	ghost.sprite_lower.material.set_shader_parameter("alpha", 0.5)
	ghost.animate_health(0)

func _physics_process(delta: float) -> void:
	if is_ghost:
		ghost_timer += delta
		sprite_lower.material.set_shader_parameter("alpha", 1.0-((0.2+ghost_timer)/0.4))
		if ghost_timer > 0.2:
			queue_free()
		return
		
	dim_time += delta
	while dim_time > dim_duration:
		dim_time -= dim_duration
	point_light.energy = dim_max - (dim_max-dim_min)*abs(dim_time-dim_duration/2)
	
	wrapping_screen()
	
	var x_input
	var y_input
	var use_stamina
	if character_id == 0:
		x_input = Input.get_joy_axis(device_id, JOY_AXIS_LEFT_X)
		y_input = Input.get_joy_axis(device_id, JOY_AXIS_LEFT_Y)
		use_stamina = Input.get_joy_axis(device_id, JOY_AXIS_TRIGGER_LEFT) >= 0.5
	else:
		x_input = Input.get_joy_axis(device_id, JOY_AXIS_RIGHT_X)
		y_input = Input.get_joy_axis(device_id, JOY_AXIS_RIGHT_Y)
		use_stamina = Input.get_joy_axis(device_id, JOY_AXIS_TRIGGER_RIGHT) >= 0.5
	
	if abs(x_input) < 0.2:
		x_input = 0
	if abs(y_input) < 0.2:
		y_input = 0
		
	if blood_particles.emitting:
		blood_timer -= delta
		if blood_timer < 0:
			blood_particles.emitting = false
			
	if !is_dashing:
		if x_input == 0 && y_input == 0:
			apply_friction(delta)
			animation_player_lower.play("stand")
		else:
			#accelerate_horizontally(x_input, delta)
			if x_input != 0:
				anchor.scale.x = sign(x_input)
			animation_player_lower.play("run")
	
	if using_stamina:
		current_stamina -= delta
		queue_redraw()
	else:
		if stamina_idle_duration >= stamina_idle_time:
			if current_stamina < max_stamina:
				current_stamina += delta*stamina_recharge_ratio
				if current_stamina > max_stamina:
					current_stamina = max_stamina
				queue_redraw()
		else:
			stamina_idle_duration += delta
		
	var use_speed = max_speed
	using_stamina = false
	if use_stamina && current_stamina > 0.0:
		using_stamina = true
		stamina_idle_duration = 0.0
		use_speed = 2 * max_speed
			
	match state:
		STATE.CLIMB:
			velocity.x = x_input * use_speed * 0.8
			velocity.y = y_input * use_speed * 0.8
			move_and_slide()
		STATE.HIT:
			move_and_slide()
		STATE.DEAD:
			is_dashing = false
			animation_player_lower.play("stand")
			apply_friction(delta)
			move_and_slide()

func wrapping_screen():
	position.x = wrapf(position.x, screen_size.position.x, screen_size.position.x + screen_size.size.x)
	position.y = wrapf(position.y, screen_size.position.y, screen_size.position.y + screen_size.size.y)

func dash(x_input, y_input) -> void:
	dash_sound.play()
	var input_dir: = Vector2(x_input, y_input).normalized()
	if input_dir.x == 0 && input_dir.y == 0:
		input_dir.x = anchor.scale.x
	
	ghost_timer = 0
	is_dashing = true
	dash_particles.emitting = true
	dash_particles_material.direction.x = -1*input_dir.x
	dash_particles_material.direction.y = -1*input_dir.y
	animation_player_upper.play("dash")
	animation_player_lower.play("dash")
	dash_timer = dash_time+dash_stop_time
	dash_cooldown_timer = dash_cooldown
	
	velocity_before_dash = velocity
	velocity_before_dash.y = 0
	dash_velocity = input_dir
	update_dash_velocity()

func accelerate_horizontally(horizontal_direction: float, delta: float) -> void:
	if is_dashing:
		return
	var acceleration_amount: = acceleration
	velocity.x = move_toward(velocity.x, max_speed * horizontal_direction, acceleration_amount * delta * abs(horizontal_direction))

func apply_friction(delta) -> void:
	if is_dashing:
		return
	var friction_amount: = friction
	velocity.x = move_toward(velocity.x, 0.0, friction_amount * delta)
	
func _draw() -> void:
	if current_stamina >= 0.0:
		var c = Color8(0,255,0,127)
		if current_stamina < max_stamina:
			c = Color8(230,189,43,127)
			if stamina_idle_duration < stamina_idle_time:
				c = Color8(255,0,0,127)
		var l = 16*current_stamina/max_stamina
		draw_rect(Rect2(-0.5*l,-36,l,1),c)

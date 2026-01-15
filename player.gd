extends CharacterBody2D

const PLAYER_SCENE = preload("res://player.tscn")
const SPARK_PARTICLE_BURST_EFFECT = preload("res://sparks_particle_burst_effect.tscn")

enum STATE { MOVE, CLIMB, HIT, DEAD }

@export var stats: PlayerStats
@export var state: = STATE.CLIMB

@export var max_speed: = 180
@export var acceleration: = 10000
@export var air_acceleration: = 2000
@export var friction: = 10000
@export var air_friction: = 10000
@export var up_gravity: = 1000
@export var down_gravity: = 1200
@export var max_gravity: = 400
@export var jump_amount: = 200
@export var jump_charge: = 0.2
@export var air_adjust_amount: = 75
@export var device_id: = 0
@export var player_id: = 0
@export var player_color: = Color8(255,255,255,255)
@export var dash_amt_start: = 500
@export var dash_amt_finish: = 180
@export var dash_time: = 0.10
@export var dash_stop_time: = 0.04
@export var dash_cooldown: = 0.5
@export var attack_rebound_time: = 0.4
@export var attack_cooldown: = 0.6

var is_dashing: = false
var dash_timer: = 0.0
var dash_cooldown_timer: = 0.0
var coyote_time: = 0.0
var dash_velocity = Vector2(0,0)
var velocity_before_dash = Vector2(0,0)
var air_adjust = 0
var screen_size = Rect2(0,0,1,1)
var attack_hold_timer = 0.0
var attack_cooldown_timer = 0.0
var jump_hold_timer = 0.0
var is_ghost = false
var ghost_timer = 0.0
var blood_timer = 0.0

@onready var player: CharacterBody2D = $"."
@onready var anchor: Node2D = $Anchor
@onready var sprite_upper: Sprite2D = $Anchor/SpriteUpper
@onready var sprite_lower: Sprite2D = $Anchor/SpriteLower
@onready var animation_player_upper: AnimationPlayer = $AnimationPlayerUpper
@onready var animation_player_lower: AnimationPlayer = $AnimationPlayerLower
@onready var effects_animation_player: AnimationPlayer = $EffectsAnimationPlayer
@onready var ray_cast_upper: RayCast2D = $Anchor/RayCastUpper
@onready var ray_cast_lower: RayCast2D = $Anchor/RayCastLower
@onready var hurtbox: Hurtbox = $Anchor/Hurtbox
@onready var hitbox: Hitbox = $Anchor/Hitbox
@onready var shaker_upper: = Shaker.new(sprite_upper)
@onready var shaker_lower: = Shaker.new(sprite_lower)
@onready var stomp_ray_left: RayCast2D = $Anchor/StompRayLeft
@onready var stomp_ray_right: RayCast2D = $Anchor/StompRayRight
@onready var stomp_ray_middle: RayCast2D = $Anchor/StompRayMiddle
@onready var jump_sound: AudioStreamPlayer = $JumpSound
@onready var dash_sound: AudioStreamPlayer = $DashSound
@onready var hit_hurt_sound: AudioStreamPlayer = $HitHurtSound
@onready var slash_sound: AudioStreamPlayer = $SlashSound
@onready var dash_particles: GPUParticles2D = $DashParticles
@onready var dash_particles_material: ParticleProcessMaterial = $DashParticles.process_material
@onready var blood_particles: GPUParticles2D = $BloodParticles
@onready var blood_particles_material: ParticleProcessMaterial = $BloodParticles.process_material
@onready var health_1: Sprite2D = $Anchor/Health1
@onready var health_2: Sprite2D = $Anchor/Health2
@onready var health_3: Sprite2D = $Anchor/Health3
@onready var hat: Sprite2D = $Anchor/Hat

func clothing_color(color):
	player_color = color
	sprite_upper.material.set_shader_parameter("clothing_end_color", player_color)

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
	
	hurtbox.hurt.connect(func(other_hitbox: Hitbox, stomp):
		if other_hitbox.damage == 0:
			hat.visible = true
			dash_time = 0.2
			return
		
		if stats.health <= 0:
			return
		
		var dir = other_hitbox.global_position.direction_to(hitbox.global_position)
		if !stomp:
			if is_dashing || (attack_hold_timer > 0 && attack_hold_timer <= attack_rebound_time):
				var spark_particle = SPARK_PARTICLE_BURST_EFFECT.instantiate()
				add_child(spark_particle)
				spark_particle.global_position = sprite_upper.global_position
				spark_particle.set_dir(dir)
				return
				
			blood_particles.emitting = true
			blood_particles_material.direction.x = dir.x
			blood_particles_material.direction.y = dir.y
			blood_timer = 0.1
		
		hit_hurt_sound.play()
		
		@warning_ignore("narrowing_conversion")
		stats.health -= other_hitbox.damage
		animate_health(stats.health)
		
		if stats.health <= 0:
			remove_collision()
			
			state = STATE.DEAD
			animation_player_upper.play("dead")
			if player_id == 0:
				Globals.roundData.blue_score += 1
			else:
				Globals.roundData.red_score += 1
			get_tree().current_scene.player_killed()
		else:
			var x_direction = sign(dir.x)
			if x_direction == 0: x_direction = -1
				 
			velocity.x = x_direction * dash_amt_finish
			@warning_ignore("integer_division")
			jump(jump_amount/2)
			
			state = STATE.HIT
			shaker_upper.shake(3, 0.3)
			shaker_lower.shake(3, 0.3)
			animation_player_lower.play("jump")
			effects_animation_player.play("hitflash")
	)
	
func animate_health(new_health):
	health_1.visible = new_health >= 1
	health_2.visible = new_health >= 2
	health_3.visible = new_health >= 3

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
	ghost.anchor.scale = anchor.scale
	ghost.sprite_lower.material.set_shader_parameter("alpha", 0.5)
	ghost.animate_health(0)

func _physics_process(delta: float) -> void:
	if is_ghost:
		ghost_timer += delta
		sprite_lower.material.set_shader_parameter("alpha", 1.0-((0.2+ghost_timer)/0.4))
		if ghost_timer > 0.2:
			queue_free()
		return
	
	wrapping_screen()
	var y_input = Input.get_joy_axis(device_id, JOY_AXIS_LEFT_Y)
	var x_input = Input.get_joy_axis(device_id, JOY_AXIS_LEFT_X)
	if abs(x_input) < 0.2:
		x_input = 0
	if abs(y_input) < 0.2:
		y_input = 0
		
	if blood_particles.emitting:
		blood_timer -= delta
		if blood_timer < 0:
			blood_particles.emitting = false
		
	match state:
		STATE.MOVE:
			dash_timer -= delta
			dash_cooldown_timer -= delta
			attack_cooldown_timer -= delta
			coyote_time -= delta
				
			if attack_cooldown_timer < 0 && (Input.is_joy_button_pressed(device_id, JOY_BUTTON_B) || Input.is_joy_button_pressed(device_id, JOY_BUTTON_X)):
				attack_hold_timer += delta
			
			if is_dashing:
				ghost_timer += delta
				if ghost_timer > 0.05:
					ghost_timer = 0.0
					add_ghost()
				if dash_timer <= 0:
					is_dashing = false
					dash_particles.emitting = false
					velocity = velocity_before_dash
				else:
					update_dash_velocity()
					
			if is_dashing || (attack_hold_timer > 0 && attack_hold_timer <= attack_rebound_time):
				sprite_lower.material.set_shader_parameter("alpha", 0.5)
			else:
				sprite_lower.material.set_shader_parameter("alpha", 1.0)
					
			if stomp_ray_left.is_colliding():
				var left_hurt = stomp_ray_left.get_collider()
				if left_hurt is Hurtbox:
					jump()
					left_hurt.take_hit(hitbox, true)
			elif stomp_ray_right.is_colliding():
				var right_hurt = stomp_ray_right.get_collider()
				if right_hurt is Hurtbox:
					jump()
					right_hurt.take_hit(hitbox, true)
			elif stomp_ray_middle.is_colliding():
				var middle_hurt = stomp_ray_middle.get_collider()
				if middle_hurt is Hurtbox:
					jump()
					middle_hurt.take_hit(hitbox, true)
			
			if !is_on_floor():
				velocity.y -= air_adjust
				
			apply_gravity(delta)
			
			if Input.is_joy_button_pressed(device_id, JOY_BUTTON_A) && (jump_hold_timer > 0 || (is_on_floor() or coyote_time > 0)):
				if jump_hold_timer == 0:
					jump_sound.play()
				jump_hold_timer += delta
				jump()
				
			if !Input.is_joy_button_pressed(device_id, JOY_BUTTON_A) || jump_hold_timer >= jump_charge:
				jump_hold_timer = 0
			
			if !Input.is_joy_button_pressed(device_id, JOY_BUTTON_B) && !Input.is_joy_button_pressed(device_id, JOY_BUTTON_X) && attack_hold_timer > 0:
				slash_sound.play()
				attack_hold_timer = 0.0
				attack_cooldown_timer = attack_cooldown
				var input_vec = Vector2(x_input, y_input)
				if input_vec == Vector2.ZERO:
					animation_player_upper.play("attack_right")
				else:
					var angle = fmod(input_vec.angle() + PI*2, PI*2)
					var sector = int(round(angle / (PI/4.0))) % 8
					if sector == 5 || sector == 7:
						animation_player_upper.play("attack_up_right")
					elif sector == 6:
						animation_player_upper.play("attack_up")
					elif (sector == 1 || sector == 3):
						animation_player_upper.play("attack_down_right")
					elif sector == 2:
						animation_player_upper.play("attack_down")
					else:
						animation_player_upper.play("attack_right")
			
			if !is_dashing:
				if x_input == 0:
					apply_friction(delta)
					animation_player_lower.play("stand")
				else:
					accelerate_horizontally(x_input, delta)
					anchor.scale.x = sign(x_input)
					animation_player_lower.play("run")
				
				if not is_on_floor():
					animation_player_lower.play("jump")
			
			if dash_cooldown_timer <= 0 && (Input.is_joy_button_pressed(device_id, JOY_BUTTON_LEFT_STICK) || Input.get_joy_axis(device_id, JOY_AXIS_TRIGGER_RIGHT) >= 0.5):
				dash(x_input, y_input)
			
			var was_on_floor: = is_on_floor()
			if !is_on_floor():
				air_adjust = y_input*air_adjust_amount
				velocity.y += air_adjust
			move_and_slide()
			if is_on_floor():
				air_adjust = 0
			if was_on_floor and not is_on_floor() and velocity.y >= 0:
				coyote_time = 0.1
			
			if should_wall_climb():
				is_dashing = false
				dash_particles.emitting = false
				sprite_lower.material.set_shader_parameter("alpha", 1.0)
				animation_player_upper.play("hang")
				state = STATE.CLIMB
			
		STATE.CLIMB:
			var wall_normal = get_wall_normal()
			
			velocity.y = y_input * max_speed * 0.8
			
			move_and_slide()
			
			if y_input != 0:
				animation_player_lower.play("climb")
			else:
				animation_player_lower.play("hang")
			
			var request_detach: bool = (sign(x_input) == wall_normal.x)
			
			var request_wall_jump: bool = (
				(request_detach or Input.is_joy_button_pressed(device_id, JOY_BUTTON_B))
				and not y_input > 0
			)
			
			if request_wall_jump:
				velocity.x = wall_normal.x * max_speed
				anchor.scale.x = sign(velocity.x)
				jump()
				state = STATE.MOVE
			
			if not should_wall_climb() or request_detach:
				if y_input < 0: jump()
				state = STATE.MOVE
		
		STATE.HIT:
			move_and_slide()
		STATE.DEAD:
			if !is_on_floor():
				velocity.y -= air_adjust
				
			apply_gravity(delta)
			
			apply_friction(delta)
			animation_player_lower.play("stand")
			
			if not is_on_floor():
				animation_player_lower.play("jump")
			
			var was_on_floor: = is_on_floor()
			if !is_on_floor():
				air_adjust = y_input*air_adjust_amount
				velocity.y += air_adjust
			move_and_slide()
			if is_on_floor():
				air_adjust = 0
			if was_on_floor and not is_on_floor() and velocity.y >= 0:
				coyote_time = 0.1

func wrapping_screen():
	position.x = wrapf(position.x, screen_size.position.x, screen_size.position.x + screen_size.size.x)
	position.y = wrapf(position.y, screen_size.position.y, screen_size.position.y + screen_size.size.y)

func jump(amount: = jump_amount) -> void:
	velocity.y = -amount

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
	if not is_on_floor(): acceleration_amount = air_acceleration
	velocity.x = move_toward(velocity.x, max_speed * horizontal_direction, acceleration_amount * delta * abs(horizontal_direction))

func apply_friction(delta) -> void:
	if is_dashing:
		return
	var friction_amount: = friction
	if not is_on_floor(): friction_amount = air_friction
	velocity.x = move_toward(velocity.x, 0.0, friction_amount * delta)

func apply_gravity(delta) -> void:
	if is_dashing:
		return
	if not is_on_floor():
		if velocity.y <= 0:
			velocity.y += up_gravity * delta
		else:
			velocity.y += down_gravity * delta
		velocity.y = min(max_gravity, velocity.y)

func should_wall_climb() -> bool:
	return (
		ray_cast_upper.is_colliding()
		and ray_cast_lower.is_colliding()
		and not is_on_floor()
	)

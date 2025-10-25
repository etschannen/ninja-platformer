extends CharacterBody2D

enum STATE { MOVE, CLIMB, HIT }

@export var stats: Stats
@export var state: = STATE.CLIMB

@export var max_speed: = 180
@export var acceleration: = 10000
@export var air_acceleration: = 2000
@export var friction: = 10000
@export var air_friction: = 10000
@export var up_gravity: = 1000
@export var down_gravity: = 1200
@export var max_gravity: = 400
@export var jump_amount: = 300
@export var air_adjust_amount: = 75
@export var device_id: = 0
@export var dash_amt_start: = 500
@export var dash_amt_finish: = 180
@export var dash_time: = 0.10
@export var dash_stop_time: = 0.04
@export var dash_cooldown: = 0.5

var is_dashing: = false
var dash_timer: = 0.0
var dash_cooldown_timer: = 0.0
var coyote_time: = 0.0
var dash_velocity = Vector2(0,0)
var velocity_before_dash = Vector2(0,0)
var air_adjust = 0
var screen_size = Rect2(0,0,1,1)

@onready var anchor: Node2D = $Anchor
@onready var sprite_upper: Sprite2D = $Anchor/SpriteUpper
@onready var sprite_lower: Sprite2D = $Anchor/SpriteLower
@onready var animation_player_upper: AnimationPlayer = $AnimationPlayerUpper
@onready var animation_player_lower: AnimationPlayer = $AnimationPlayerLower
@onready var effects_animation_player: AnimationPlayer = $EffectsAnimationPlayer
@onready var ray_cast_upper: RayCast2D = $Anchor/RayCastUpper
@onready var ray_cast_lower: RayCast2D = $Anchor/RayCastLower
@onready var hurtbox: Hurtbox = $Anchor/Hurtbox
@onready var shaker_upper: = Shaker.new(sprite_upper)
@onready var shaker_lower: = Shaker.new(sprite_lower)

func _ready() -> void:
	var viewport_size = get_viewport_rect().size
	var top_left = get_viewport().canvas_transform.affine_inverse()*Vector2(0,0)
	var bottom_right = get_viewport().canvas_transform.affine_inverse()*viewport_size
	screen_size = Rect2(top_left, bottom_right-top_left)
	
	stats.no_health.connect(func():
		queue_free()
	)
	
	sprite_lower.material.set_shader_parameter("flash_color", Color("ff4d4d"))
	
	animation_player_lower.current_animation_changed.connect(func(animation_name: String):
		if animation_player_upper.current_animation == "attack": return
		animation_player_upper.play(animation_name)
	)
	
	animation_player_upper.animation_finished.connect(func(animation_name: String):
		if animation_name != "attack": return
		animation_player_upper.play(animation_player_lower.current_animation)
		animation_player_upper.seek(animation_player_lower.current_animation_position)
	)
	
	hurtbox.hurt.connect(func(other_hitbox: Hitbox):
		var x_direction = sign(other_hitbox.global_position.direction_to(global_position).x)
		if x_direction == 0: x_direction = -1
		velocity.x = x_direction * dash_amt_finish
		@warning_ignore("integer_division")
		jump(jump_amount/2)
		state = STATE.HIT
		shaker_upper.shake(3, 0.3)
		shaker_lower.shake(3, 0.3)
		animation_player_lower.play("jump")
		effects_animation_player.play("hitflash")
		@warning_ignore("narrowing_conversion")
		stats.health -= other_hitbox.damage
	)
	
	effects_animation_player.play("RESET")

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

func _physics_process(delta: float) -> void:
	wrapping_screen()
	var y_input = Input.get_joy_axis(device_id, JOY_AXIS_LEFT_Y)
	var x_input = Input.get_joy_axis(device_id, JOY_AXIS_LEFT_X)
	if abs(x_input) < 0.2:
		x_input = 0
	if abs(y_input) < 0.2:
		y_input = 0
	match state:
		STATE.MOVE:
			dash_timer -= delta
			dash_cooldown_timer -= delta
			coyote_time -= delta
			
			if is_dashing:
				if dash_timer <= 0:
					is_dashing = false
					velocity = velocity_before_dash
				else:
					update_dash_velocity()
			
			apply_gravity(delta)
			
			if Input.is_joy_button_pressed(device_id, JOY_BUTTON_A) and (is_on_floor() or coyote_time > 0):
				jump()
			
			if Input.is_joy_button_pressed(device_id, JOY_BUTTON_B) || Input.is_joy_button_pressed(device_id, JOY_BUTTON_X):
				animation_player_upper.play("attack")
			
			if x_input == 0:
				apply_friction(delta)
				animation_player_lower.play("stand")
			else:
				accelerate_horizontally(x_input, delta)
				anchor.scale.x = sign(x_input)
				animation_player_lower.play("run")
			
			if not is_on_floor():
				animation_player_lower.play("jump")
			
			if (Input.is_joy_button_pressed(device_id, JOY_BUTTON_LEFT_STICK) || Input.get_joy_axis(device_id, JOY_AXIS_TRIGGER_RIGHT) >= 0.5) and dash_cooldown_timer <= 0:
				dash(x_input, y_input)
			
			var was_on_floor: = is_on_floor()
			if !is_on_floor():
				velocity.y -= air_adjust
				air_adjust = y_input*air_adjust_amount
				velocity.y += air_adjust
			move_and_slide()
			if is_on_floor():
				air_adjust = 0
			if was_on_floor and not is_on_floor() and velocity.y >= 0:
				coyote_time = 0.1
			
			if should_wall_climb():
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
			#apply_friction(delta)
			#apply_gravity(delta)

func wrapping_screen():
	position.x = wrapf(position.x, screen_size.position.x, screen_size.position.x + screen_size.size.x)
	position.y = wrapf(position.y, screen_size.position.y, screen_size.position.y + screen_size.size.y)

func jump(amount: = jump_amount) -> void:
	velocity.y = -amount

func dash(x_input, y_input) -> void:
	var input_dir: = Vector2(x_input, y_input).normalized()
	if input_dir.x == 0 && input_dir.y == 0:
		input_dir.x = anchor.scale.x
	
	is_dashing = true
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

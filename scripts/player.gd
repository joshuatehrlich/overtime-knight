extends CharacterBody2D

const RUN_SPEED: float = 180.0
const RUN_ACCEL: float = 2000.0
const RUN_DECEL: float = 2000.0
const RUN_ACCEL_AIR_FACTOR: float = 0.75

const JUMP_SPEED: float = 450
const JUMP_RELEASE_DROP_MULTIPLIER: float = 0.8
const JUMP_HOLD_GRAVITY_FACTOR: float = 0.5
const JUMP_HOLD_VELOCITY_THRESHOLD: float = 100.0
const TERMINAL_FALL_SPEED: float = 500

const COYOTE_TIME_SECS: float = 0.1

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var sprite_2d: Sprite2D = $Sprite2D

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity") * 1.5
var gravity_coeff: float = 1.0


func _physics_process(delta: float) -> void:
	handle_movement(delta)
	handle_animation()

func handle_movement(delta: float) -> void:
	handle_movement_gravity(delta)
	handle_movement_run(delta)
	handle_movement_jump(delta)

	move_and_slide()

func handle_movement_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y = move_toward(velocity.y, TERMINAL_FALL_SPEED, gravity * gravity_coeff * delta)

func handle_movement_run(delta: float) -> void:
	var direction := Input.get_action_strength("right") - Input.get_action_strength("left")
	
	var norm_vel := velocity.x / RUN_SPEED
	var norm_target_vel := direction
	var is_decelerating: bool = (norm_vel * norm_target_vel <= 0) && (abs(norm_vel) > abs(norm_target_vel))
	var accel = RUN_DECEL if is_decelerating else RUN_ACCEL
	var accel_coeff = 1 if is_on_floor() else RUN_ACCEL_AIR_FACTOR
	
	velocity.x = move_toward(velocity.x, direction * RUN_SPEED, accel * accel_coeff * delta)

var last_jump_input: float = INF
var last_grounded: float = INF

var is_jumping: bool

func handle_movement_jump(delta: float) -> void:
	last_jump_input += delta
	last_grounded += delta
	
	if Input.is_action_just_pressed("jump"):
		last_jump_input = 0.0
	
	if is_on_floor():
		last_grounded = 0.0
		is_jumping = false
		
	if (is_on_floor() or last_grounded <= COYOTE_TIME_SECS) and last_jump_input <= COYOTE_TIME_SECS and not is_jumping:
		velocity.y = -JUMP_SPEED
		is_jumping = true
	elif abs(velocity.y) < JUMP_HOLD_VELOCITY_THRESHOLD && Input.is_action_pressed("jump"):
		gravity_coeff = JUMP_HOLD_GRAVITY_FACTOR
	else:
		gravity_coeff = 1.0
		
	if velocity.y < 0 and not Input.is_action_pressed("jump"):
		velocity.y *= JUMP_RELEASE_DROP_MULTIPLIER
		
	print(velocity.y)

func handle_animation():
	# Determine input direction
	var direction = Input.get_action_strength("right") - Input.get_action_strength("left")
	
	# Scale character horizontally to make them face the direction of input at all times
	if direction != 0:
		sprite_2d["scale"] = Vector2(sign(direction), 1)
	
	# Jumping Case
	if not is_on_floor():
		animation_tree["parameters/conditions/grounded"] = false
		animation_tree["parameters/conditions/airborne"] = true
		animation_tree["parameters/land/blend_position"] = ((abs(direction)-.5)*2)
		animation_tree["parameters/airborne/blend_position"] = Vector2((((abs(velocity.x)/RUN_SPEED)-.5)*2), sign(velocity.y)) # Expression for the first number in this vector 2 turns our x velocity into a number where -1 represents not moving, while 1 represents full speed.
		return # Grounded case is not executed
	
	# Grounded Case
	animation_tree["parameters/grounded/blend_position"] = (((abs(velocity.x)/RUN_SPEED)-.5)*2)
	animation_tree["parameters/conditions/grounded"] = true
	animation_tree["parameters/conditions/airborne"] = false

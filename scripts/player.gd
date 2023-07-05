extends CharacterBody2D

@export_category("Movement Parameters")
@export var RUN_SPEED: float = 200.0
@export var RUN_ACCEL: float = 1000.0
@export var RUN_DECEL: float = 1000.0
@export var RUN_ACCEL_AIR_FACTOR: float = 0.65

@export var JUMP_SPEED: float = 200
@export var JUMP_HOLD_GRAVITY_FACTOR: float = 0.5
@export var TERMINAL_FALL_SPEED: float = 500

@export var COYOTE_TIME_SECS: float = 0.1

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var sprite_2d: Sprite2D = $Sprite2D

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity") * 2
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

func handle_movement_jump(delta: float) -> void:
	last_jump_input += delta
	last_grounded += delta
	
	if Input.is_action_just_pressed("jump"):
		last_jump_input = 0.0
	
	if is_on_floor():
		last_grounded = 0.0
		
	if (is_on_floor() || last_grounded <= COYOTE_TIME_SECS) && last_jump_input <= COYOTE_TIME_SECS:
		velocity.y = -JUMP_SPEED
	elif abs(velocity.y) < 200.0 && Input.is_action_pressed("jump"):
		gravity_coeff = JUMP_HOLD_GRAVITY_FACTOR
	else:
		gravity_coeff = 1.0

func handle_animation():
	# Determine input direction
	var direction := Input.get_action_strength("right") - Input.get_action_strength("left")
	
	# Scale character horizontally to make them face the direction of input at all times
	if direction != 0:
		sprite_2d["scale"] = Vector2(sign(direction), 1)
	
	# Jumping Case
	if not is_on_floor():
		animation_tree["parameters/conditions/airborne"] = true
		animation_tree["parameters/airborne/blend_position"] = -sign(velocity.y)
		animation_tree["parameters/conditions/is_moving"] = false
		animation_tree["parameters/conditions/idle"] = false
		return
	
	# Grounded Case
	animation_tree["parameters/conditions/airborne"] = false
	if direction == 0:
		animation_tree["parameters/conditions/idle"] = true
		animation_tree["parameters/conditions/is_moving"] = false
	else:
		animation_tree["parameters/conditions/idle"] = false
		animation_tree["parameters/conditions/is_moving"] = true

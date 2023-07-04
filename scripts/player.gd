extends CharacterBody2D

const RUN_SPEED: float = 180.0
const RUN_ACCEL: float = 2000.0
const RUN_DECEL: float = 800.0
const RUN_ACCEL_AIR_FACTOR: float = 0.65

const JUMP_SPEED: float = 350.0

const COYOTE_TIME_SECS: float = 0.1

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var sprite_2d: Sprite2D = $Sprite2D

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")


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
		velocity.y += gravity * delta

func handle_movement_run(delta: float) -> void:
	var direction := Input.get_action_strength("right") - Input.get_action_strength("left")
	
	var norm_vel := velocity.x / RUN_SPEED
	var norm_target_vel := direction
	var is_accelerating := norm_vel * norm_target_vel >= 0
	var accel = RUN_ACCEL if is_accelerating else RUN_DECEL
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

extends CharacterBody2D

const SPEED = 150.0
const JUMP_VELOCITY = -350.0

@onready var animation_tree : AnimationTree = $AnimationTree
@onready var sprite_2d : Sprite2D = $Sprite2D

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Jump implmentation courtesy of: https://www.youtube.com/watch?v=fE8f5-ZHD_k
var jump_height = 75
var jump_up_time = 0.3
var jump_fall_time = 0.2

@onready var jump_velocity : float = ((2.0 * jump_height) / jump_up_time) * -1.0
@onready var jump_gravity : float = ((-2.0 * jump_height) / (jump_up_time * jump_up_time)) * -1.0
@onready var fall_gravity : float = ((-2.0 * jump_height) / (jump_fall_time * jump_fall_time)) * -1.0

func _physics_process(delta):
	handle_movement(delta)
	handle_animation()

func handle_movement(delta):
	if velocity.y < 0.0:
		velocity.y += jump_gravity * delta
	else:
		velocity.y += fall_gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_action_strength("right") - Input.get_action_strength("left")
	if direction != 0:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

func handle_animation():
	# Determine input direction
	var direction = Input.get_action_strength("right") - Input.get_action_strength("left")
	
	# Scale character horizontally to make them face the direction of input at all times
	if direction != 0:
		sprite_2d["scale"] = Vector2(sign(direction), 1)
	
	# Jumping Case
	if (!is_on_floor()):
		animation_tree["parameters/conditions/airborne"] = true
		animation_tree["parameters/airborne/blend_position"] = -sign(velocity.y)
		animation_tree["parameters/conditions/is_moving"] = false
		animation_tree["parameters/conditions/idle"] = false
		return
	
	# Grounded Case
	animation_tree["parameters/conditions/airborne"] = false
	if (direction) == 0:
		animation_tree["parameters/conditions/idle"] = true
		animation_tree["parameters/conditions/is_moving"] = false
	else:
		animation_tree["parameters/conditions/idle"] = false
		animation_tree["parameters/conditions/is_moving"] = true

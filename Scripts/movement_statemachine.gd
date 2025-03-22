extends CharacterBody2D

var speed = 65  # Walking speed

func _ready():
	print("Player is ready for movement.")

func _process(delta):
	# Handle movement input
	handle_movement_input()

	# Apply movement (move_and_slide() will use velocity automatically)
	move_and_slide()  # This works because velocity is already part of CharacterBody2D

# Function to handle movement input (walking)
func handle_movement_input():
	# Get input direction (using action strength, which returns 0 or 1 based on keypress)
	var input_vector = Vector2(
		Input.get_action_strength("walk_right") - Input.get_action_strength("walk_left"),
		Input.get_action_strength("walk_down") - Input.get_action_strength("walk_up")
	)

	# Normalize the input vector to prevent faster diagonal movement
	if input_vector != Vector2.ZERO:
		input_vector = input_vector.normalized()

	# Set the velocity based on the input and speed
	velocity = input_vector * speed  # This directly sets the built-in velocity

	# Debug output to show the velocity
	print("Velocity: ", velocity)

# CharacterPlayer2D.gd
extends CharacterBody2D

# Define movement speed
var speed : float = 65

# AnimationPlayer node reference
@onready var animation_player : AnimationPlayer = $AnimationPlayer

func _ready():
	# Set the default animation to "idle" when the game starts
	animation_player.play("idle")

func _process(delta):
	# Get input for movement
	var direction = Vector2.ZERO
	
	if Input.is_action_pressed("walk_right"):
		direction.x += 1
	if Input.is_action_pressed("walk_left"):
		direction.x -= 1
	if Input.is_action_pressed("walk_down"):
		direction.y += 1
	if Input.is_action_pressed("walk_up"):
		direction.y -= 1
	
	# Normalize direction to avoid faster diagonal movement
	direction = direction.normalized()

	# Set the velocity for the character
	velocity = direction * speed

	# Move the character using move_and_slide() (no argument needed)
	move_and_slide()

	# Change animation based on direction
	if direction.y > 0:
		animation_player.play("walk_down")
	elif direction.y < 0:
		animation_player.play("walk_up")
	elif direction.x > 0:
		animation_player.play("walk_right")
	elif direction.x < 0:
		animation_player.play("walk_left")
	else:
		# Optionally, play an idle animation if no movement
		animation_player.play("idle")

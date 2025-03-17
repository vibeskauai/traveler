extends Area2D

@export var item_name: String  # Name of the item (e.g., "Hollowed Pickaxe")
@export var item_type: String  # Type of item (e.g., "weapon", "resource")
@export var item_texture: Texture  # Texture for the item icon
@onready var sprite = $Sprite2D  # Ensure this is correctly referencing your Sprite2D
@onready var collision = $CollisionShape2D  # Ensure this is correctly referencing the CollisionShape2D

var player_in_range = false

signal picked_up(item_name: String, item_type: String)  # Signal when the item is picked up

var is_picked_up = false  # To ensure the item is only picked up once

func _ready():
	# Check if the sprite node exists before trying to assign the texture
	if sprite:
		# Set the item texture if provided
		if item_texture:
			sprite.texture = item_texture
		else:
			print("Warning: No texture assigned for item: ", item_name)
	else:
		print("Error: Sprite node not found for item: ", item_name)

	# Ensure the collision shape is enabled
	collision.disabled = false

	# Connect signals
	connect("body_entered", Callable(self, "_on_Area2D_body_entered"))
	connect("body_exited", Callable(self, "_on_Area2D_body_exited"))

func _on_Area2D_body_entered(body):
	# Detect when the player enters the area of the item
	if body.is_in_group("player") and !is_picked_up:
		player_in_range = true  # Player is near the item
		print("Player entered the area of the pickaxe.")

func _on_Area2D_body_exited(body):
	# Detect when the player exits the area of the item
	if body.is_in_group("player"):
		player_in_range = false  # Player has left the item area
		print("Player exited the area of the pickaxe.")

func _process(delta):
	# Check if the player presses the "pick_up" button while in range
	if player_in_range and Input.is_action_just_pressed("pick_up") and !is_picked_up:  # Ensure it isn't picked up twice
		is_picked_up = true  # Mark the item as picked up
		emit_signal("picked_up", item_name, item_type)  # Emit the signal with item data
		queue_free()  # Remove the item from the scene
		print("Pickaxe picked up!")

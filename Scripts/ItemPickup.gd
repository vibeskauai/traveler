extends Area2D

@export var item_name: String  # Display-only (optional)
@export var item_type: String  # Display-only (optional)
@export var item_texture: Texture
@export var item_path: String  # Ex: "res://assets/items/HollowedPickaxe.tres"

@onready var sprite = $Sprite2D
@onready var collision = $CollisionShape2D

var player_in_range = false
var is_picked_up = false

func _ready():
	if sprite:
		if item_texture:
			sprite.texture = item_texture
		else:
			print("⚠️ No texture assigned for item:", item_name)
	else:
		print("❌ Sprite node missing!")

	collision.disabled = false

	connect("body_entered", Callable(self, "_on_Area2D_body_entered"))
	connect("body_exited", Callable(self, "_on_Area2D_body_exited"))

func _on_Area2D_body_entered(body):
	if body.is_in_group("player") and !is_picked_up:
		player_in_range = true
		print("🧍 Player entered pickup area.")

func _on_Area2D_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		print("🚶 Player left pickup area.")

func _process(delta):
	if player_in_range and Input.is_action_just_pressed("pick_up") and !is_picked_up:
		var item = load(item_path) as ItemResource  # Load the ItemResource
		if item:
			var player = get_tree().get_first_node_in_group("player")
			if player:
				# Assuming drop_amount is available (set this accordingly)
				var drop_amount = 1  # Example, you can replace this with the actual drop amount
				PlayerStats.add_item_to_inventory(item, drop_amount)  # Pass item and drop_amount
				print("✅ Picked up:", item.item_name)
			else:
				print("❌ Player not found in group.")
		else:
			print("❌ Failed to load item resource from path:", item_path)

		is_picked_up = true
		queue_free()

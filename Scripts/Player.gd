extends CharacterBody2D

var speed = 65  # Walking speed
var swing_cooldown = 0.5  # Cooldown time for swing in seconds
var swing_timer = 0.3  # Timer to track cooldown for swing animation

# Reference to AnimatedSprite2D node
@onready var sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer
@onready var player = get_tree().get_first_node_in_group("player")  # Get the player node
@onready var player_stats = get_node("/root/PlayerStats")  # Assuming PlayerStats is a singleton or part of the scene
@onready var raycast = $RayCast2D  # Access the RayCast2D node
@onready var global_state = GlobalState  # Reference to the GlobalState singleton
@onready var pickaxe_sprite = $PickaxeSprite
@onready var inventory_panel = get_tree().get_first_node_in_group("inventory_panel")  # ✅ Uses group instead of fixed path
@onready var armor_panel = get_tree().get_first_node_in_group("armor_ui")  # Find Armor UI dynamically
@onready var pickaxe_hitbox := $PickaxeSprite/hitbox
@onready var main_ui = get_tree().get_first_node_in_group("main_ui")
@export var ore_type: String = ""

var equipped_item = null  # Currently equipped item

var is_auto_mining: bool = false  # Flag to track whether auto-mining is active
var target_ore: Node = null  # Target ore to mine
var is_mining: bool = false  # Flag to track mining status
var is_swinging = false

# Variable to store last movement direction animation name
var last_direction = ""  # This can be "walk_right", "walk_left", "walk_down", "walk_up"
var last_position: Vector2 = Vector2(0, 0)  # Store last position to detect changes
# Track if the swing animation is already playing

func _ready():
	# When the game or scene starts, load the last animation from GlobalState
	if GlobalState.last_animation_played != "":
		animation_player.play(GlobalState.last_animation_played)  # Play the saved animation
	else:
		animation_player.play("idle")  # Default to "idle" if no saved state exists
	GlobalState.load_game_data()  # ✅ Load save data on startup
	set_global_position(GlobalState.player_position)  # ✅ Apply saved player position
	update_pickaxe_visibility()  # ✅ Restore pickaxe visibility
	print("Player ready. Checking GlobalState position:", GlobalState.player_position)
	add_to_group("player")  # Add this to the player's _ready() method
	
	# ✅ Ensure proper player positioning on load
	if GlobalState.is_new_game:
		print("🆕 New game detected! Setting player position to:", GlobalState.player_position)
		self.position = GlobalState.player_position
	else:
		print("📂 Loading saved data...")
		global_state.load_game_data()
		self.position = global_state.player_position  # Load the saved position

	print("✅ Final player position after setup:", self.position)

	# ✅ Ensure Last Facing Direction is Loaded Before Use
	if GlobalState.last_facing_direction == Vector2.ZERO:
		print("⚠️ No saved facing direction found. Defaulting to left.")
		GlobalState.last_facing_direction = Vector2(-1, 0)  # Default to left
	else:
		print("↔️ Loaded last facing direction:", GlobalState.last_facing_direction)

	# ✅ APPLY THE LOADED FACING DIRECTION **AFTER** LOADING EVERYTHING
	call_deferred("apply_loaded_facing_direction")

	# ✅ Store initial position to track movement changes
	last_position = self.position

	# ✅ Connect signals for interactable items (e.g., pickups)
	var items = get_tree().get_nodes_in_group("pickups")
	for item in items:
		item.connect("picked_up", Callable(self, "_on_item_picked_up"))

func _process(delta):
	var direction = Vector2.ZERO  # Initialize direction

	# Handle swing input
	if Input.is_action_just_pressed("swing") and swing_timer <= 0 and not is_swinging:
		is_swinging = true
		perform_swing()  # Trigger the swing and start the animation

	# Handle auto-mining logic
	if is_auto_mining and target_ore:
		var distance = global_position.distance_to(target_ore.global_position)
		if distance > 50:  # Stop auto-mining if player is too far from the ore
			print("❌ Player walked away from ore, stopping auto-mining.")
			stop_auto_mining()

	# Handle movement input
	var input_vector: Vector2 = Vector2(
		Input.get_action_strength("walk_right") - Input.get_action_strength("walk_left"),
		Input.get_action_strength("walk_down") - Input.get_action_strength("walk_up")
	)

	# Normalize the input vector to avoid faster diagonal movement
	if input_vector != Vector2.ZERO:
		input_vector = input_vector.normalized()

	# Update the player's facing direction based on input
	if input_vector != Vector2.ZERO:
		GlobalState.update_last_facing_direction(input_vector)

	# Apply movement (only if not swinging)
	if !is_swinging:
		# Apply the movement direction and speed to the velocity
		velocity = input_vector * speed  # Set velocity directly based on input and speed

	# Move the player
	move_and_slide()  # No need to pass the velocity, it's handled automatically by CharacterBody2D

	# Update walking animation if player is not swinging
	if !is_swinging:
		update_movement_animation()

	# Update swing timer and stop swing when done
	if swing_timer > 0:
		swing_timer -= delta  # Decrease swing cooldown
	if is_swinging and !animation_player.is_playing():  # Check if the swing animation finished
		is_swinging = false
		reset_to_last_direction_animation()

	sync_player_position()  # Sync player position for save/load or updates


# Update the player velocity while handling swinging logic
func update_player_velocity() -> Vector2:
	if is_swinging:
		# Prevent movement when swinging
		return Vector2.ZERO
	else:
		# Gather movement input and calculate velocity
		var velocity: Vector2 = Vector2.ZERO
		if Input.is_action_pressed("walk_right"):
			velocity.x += 1
		if Input.is_action_pressed("walk_left"):
			velocity.x -= 1
		if Input.is_action_pressed("walk_down"):
			velocity.y += 1
		if Input.is_action_pressed("walk_up"):
			velocity.y -= 1

		# Normalize movement vector and scale by speed
		if velocity != Vector2.ZERO:
			velocity = velocity.normalized() * speed
		
		return velocity

# Handle movement animation when not swinging
func update_movement_animation():
	var current_direction = ""
	if Input.is_action_pressed("walk_right"):
		current_direction = "walk_right"
	elif Input.is_action_pressed("walk_left"):
		current_direction = "walk_left"
	elif Input.is_action_pressed("walk_down"):
		current_direction = "walk_down"
	elif Input.is_action_pressed("walk_up"):
		current_direction = "walk_up"

	# Only play walking animations when the pickaxe is equipped
	if "pickaxe" in GlobalState.equipped_items:
		animation_player.play(current_direction + "_with_pickaxe")
	else:
		animation_player.play(current_direction)

# Reset to last direction animation after swing finishes
func reset_to_last_direction_animation():
	var last_direction = GlobalState.last_facing_direction
	if "pickaxe" in GlobalState.equipped_items:
		match last_direction:
			"walk_right": animation_player.play("walk_right_with_pickaxe")
			"walk_left": animation_player.play("walk_left_with_pickaxe")
			"walk_down": animation_player.play("walk_down_with_pickaxe")
			"walk_up": animation_player.play("walk_up_with_pickaxe")
	else:
		match last_direction:
			"walk_right": animation_player.play("walk_right")
			"walk_left": animation_player.play("walk_left")
			"walk_down": animation_player.play("walk_down")
			"walk_up": animation_player.play("walk_up")
	animation_player.seek(0)  # Ensure the animation starts from the first frame

# Function to change the animation and update GlobalState
func change_animation(animation_name: String):
	# Only change if the animation is different to prevent unnecessary updates
	if animation_name != GlobalState.last_animation_played:
		animation_player.play(animation_name)  # Play the new animation
		GlobalState.last_animation_played = animation_name  # Update GlobalState with the current animation

func _on_new_game_started(new_position: Vector2):
	global_position = new_position

# Function to sync the player's position with GlobalState
func sync_player_position():
	if GlobalState.is_new_game:
		return  # Prevents saving old position after a new game is started!

	GlobalState.player_position = position
	GlobalState.save_all_data()

# Save player position and other necessary game data
func save_player_position():
	if GlobalState.is_new_game:
		print("Skipping save_player_position() - new game in progress.")
		return  # Prevents overwriting the new game position

	GlobalState.player_position = position
	GlobalState.save_all_data()

# Called when an inventory item is clicked to toggle pickaxe equip
func _on_item_button_pressed(item: ItemResource):
	if player_stats.is_item_equipped(item.resource_path):
		player_stats.unequip_item(item.equip_slot)
	else:
		player_stats.equip_item(item.equip_slot, item.resource_path)

	update_inventory_panel()
	update_pickaxe_visibility()



func update_pickaxe_visibility():
	var pickaxe_path = player_stats.equipped_items.get("weapon", "")
	if has_node("PickaxeSprite"):
		var pickaxe_sprite = get_node("PickaxeSprite")
		if pickaxe_path != "":
			var item = load(pickaxe_path)
			if item and item is ItemResource:
				pickaxe_sprite.texture = item.icon
				pickaxe_sprite.visible = true
			else:
				print("❌ Pickaxe icon missing or invalid item:", pickaxe_path)
		else:
			pickaxe_sprite.visible = false



func _on_item_picked_up(item_name: String, item_type: String):
	var item_path = "res://assets/items/" + item_name + ".tres"
	if FileAccess.file_exists(item_path):
		var item = load(item_path)
		if item and item is ItemResource:
			add_item_to_inventory(item)
		else:
			print("❌ Failed to load ItemResource:", item_path)
	else:
		print("❌ Item file not found:", item_path)

	update_inventory_panel()



# Function to add the item to the inventory
func add_item_to_inventory(item: ItemResource, quantity: int = 1):
	for entry in player_stats.inventory:
		if entry.path == item.resource_path:
			entry.quantity += quantity
			sync_inventory_with_global_state()
			return
	
	# Add new item
	player_stats.inventory.append({
		"path": item.resource_path,
		"quantity": quantity
	})
	sync_inventory_with_global_state()


# Function to sync inventory with GlobalState
func sync_inventory_with_global_state():
	print("✅ Syncing inventory with GlobalState...")

	# Save inventory to GlobalState
	GlobalState.inventory = player_stats.inventory
	GlobalState.save_all_data()

	# Force UI to update
	if inventory_panel:
		print("🔄 Updating Inventory UI after sync...")
		inventory_panel.update_inventory_ui()
	else:
		print("❌ ERROR: inventory_panel is NULL!")

func equip_item_from_inventory(slot_type, item_name):
	print("✅ Calling equip_item_from_inventory() for:", item_name)
	player_stats.equip_item(slot_type, item_name)
	update_pickaxe_visibility()


func unequip_item(slot_type):
	print("✅ Calling unequip_item() for:", slot_type)
	player_stats.unequip_item(slot_type)
	update_pickaxe_visibility()


func apply_loaded_facing_direction():
	# Verify the AnimatedSprite2D node exists
	if not animation_player:
		print("ERROR: AnimatedSprite2D node not found!")
		return

	var d: Vector2 = GlobalState.last_facing_direction
	
	var new_anim = ""
	if d == Vector2.ZERO:
		new_anim = "walk_down"
	else:
		if abs(d.x) > abs(d.y):
			# Horizontal movement is dominant.
			if d.x < 0:
				new_anim = "walk_left"
			else:
				new_anim = "walk_right"
		else:
			# Vertical movement is dominant.
			if d.y < 0:
				new_anim = "walk_up"
			else:
				new_anim = "walk_down"
	# Play the determined animation using AnimationPlayer
	animation_player.play(new_anim)

	# Reset the frame to the start (optional, depending on your animation setup)
	sprite.frame = 0

	# Store the direction for idle use
	last_direction = new_anim

func on_item_equipped(slot_type: String, item_path: String):
	if slot_type == "weapon":
		update_pickaxe_visibility()

func on_item_unequipped(slot_type: String, item_path: String):
	if slot_type == "weapon":
		update_pickaxe_visibility()


func get_slot_for_item_type(item_type: String) -> String:
	match item_type:
		"weapon", "pickaxe":
			return "weapon"  # ✅ Pickaxes go in the weapon slot
		"helm":
			return "helm"
		"chest":
			return "chest"
		"legs":
			return "legs"
		"shield":
			return "shield"
	return ""  # Invalid item type


func update_inventory_panel():
	if inventory_panel:
		print("✅ Updating Inventory Panel...")
		if inventory_panel.has_method("update_inventory_ui"):
			inventory_panel.update_inventory_ui()
		else:
			print("❌ ERROR: InventoryPanel does not have update_inventory_ui()!")
	else:
		print("❌ ERROR: InventoryPanel not found!")

func _on_area_2d_area_entered(area: Area2D) -> void:
	pass # Replace with function body.

# Function to return the swing animation based on the last movement direction
func get_swing_animation() -> String:
	var direction = GlobalState.last_facing_direction  # Get direction from GlobalState
	if direction.x > 0:
		return "swing_right_with_pickaxe"
	elif direction.x < 0:
		return "swing_left_with_pickaxe"
	elif direction.y > 0:
		return "swing_down_with_pickaxe"  # Swing downward
	elif direction.y < 0:
		return "swing_up_with_pickaxe"  # Swing upward
	return ""  # Default to empty string if no valid direction

# Perform the swing animation
func perform_swing():
	if swing_timer <= 0:  # Ensure the cooldown has passed
		var swing_animation = get_swing_animation()

		if swing_animation != "":
			print("Playing swing animation: ", swing_animation)
			animation_player.play(swing_animation)  # Play the swing animation
			swing_timer = get_animation_duration(swing_animation)  # Set cooldown based on animation duration
		else:
			print("No swing animation found.")

		# Ensure the pickaxe hitbox is enabled during the swing
		var pickaxe_hit_area = $PickaxeSprite/hitbox  # Assuming hitbox is an Area2D
		if pickaxe_hit_area:
			pickaxe_hit_area.monitoring = true  # Ensure monitoring is enabled

			# Check for interaction with ores using the hit area
			var ore_node = null
			var collided_areas = pickaxe_hit_area.get_overlapping_areas()

			print("⛏️ Collided areas count: ", collided_areas.size())  # Debug output
			for area in collided_areas:
				print("⛏️ Area found:", area.name)  # Debug output
				if area.is_in_group("ores"):  # Ensure that we're detecting ore nodes
					ore_node = area.get_parent()  # Get the parent node (OreNode)
					print("⛏️ Ore node detected:", ore_node.ore_type)  # Debug output (Checking ore_type)
					break  # Stop the loop once the ore is found

			if ore_node:
				print("⛏️ Ore detected during swing:", ore_node.ore_type)  # Debug output
				# Trigger auto-mining if enabled and ore type matches
				if is_auto_mining:
					print("⛏️ Auto-mining flag is TRUE. Starting auto-mining for ore:", ore_node.ore_type)  # Debug output
					target_ore = ore_node  # Set the target ore for auto-mining
					start_auto_mining()  # Start auto-mining
				else:
					print("⛏️ Auto-mining flag is FALSE. Setting it to TRUE.")  # Debug output
					is_auto_mining = true  # Set the auto-mining flag to true
					target_ore = ore_node  # Set the target ore for auto-mining
					start_auto_mining()  # Start auto-mining

		# Ensure the animation is connected only once and only during the swing
		animation_player.connect("animation_finished", Callable(self, "_on_animation_finished"))

	else:
		print("⛏️ No swing animation found.")

# Called when the animation is finished
func _on_animation_finished(anim_name):
	if anim_name == "swing_right_with_pickaxe" or anim_name == "swing_left_with_pickaxe" or anim_name == "swing_down_with_pickaxe" or anim_name == "swing_up_with_pickaxe":
		is_swinging = false  # Reset the swing state when the animation finishes

		# Stop auto-mining if the player isn't swinging anymore
		if is_auto_mining:
			stop_auto_mining()
			is_auto_mining = false  # Reset the auto-mining flag

		# Disconnect the animation finished signal to avoid repeated triggering
		animation_player.disconnect("animation_finished", Callable(self, "_on_animation_finished"))
		
		# After the swing is finished, return to the walking animation
		reset_to_last_direction_animation()

# Helper function to get the duration of the current animation
func get_animation_duration(animation_name: String) -> float:
	if animation_player.has_animation(animation_name):
		return animation_player.get_animation(animation_name).length  # Return the animation duration
	return 1.0  # Default duration if animation is not found


func start_auto_mining():
	if not target_ore:
		print("❌ No target ore set for auto-mining!")  # Debug output
		return  # Ensure we have a target ore to mine

	is_mining = true
	print("⛏️ Auto-mining started on", target_ore.ore_type)  # Debug output

	# Start the mining loop immediately (now in OreNode.gd)
	target_ore.start_auto_mining()  # This will now handle the mining in OreNode.gd


func stop_auto_mining():
	if not is_auto_mining:
		return  # Auto-mining is already stopped

	print("⛏️ Stopping auto-mining.")  # Debug output
	is_auto_mining = false
	target_ore = null  # Clear the target ore
	is_mining = false  # Set mining flag to false

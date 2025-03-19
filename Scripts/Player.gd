extends CharacterBody2D

var speed = 80  # Walking speed
var swing_cooldown = 0.5  # Cooldown time for swing in seconds
var swing_timer = 0.0  # Timer to track cooldown for swing animation

# Reference to AnimatedSprite2D node
@onready var animated_sprite = $AnimatedSprite2D
@onready var player_stats = get_node("/root/PlayerStats")  # Assuming PlayerStats is a singleton or part of the scene
@onready var raycast = $RayCast2D  # Access the RayCast2D node
@onready var global_state = GlobalState  # Reference to the GlobalState singleton
@onready var pickaxe_sprite = $PickaxeSprite
@onready var inventory_panel = get_tree().get_first_node_in_group("inventory_panel")  # ✅ Uses group instead of fixed path



var equipped_item = null  # Currently equipped item
var automining = false  # Track if the player is automining
# Variable to store last movement direction animation name
var last_direction = ""  # This can be "walk_right", "walk_left", "walk_down", "walk_up"
var last_position: Vector2 = Vector2(0, 0)  # Store last position to detect changes
# Track if the swing animation is already playing
var is_swinging = false

func _ready():
	print("Player ready. Checking GlobalState position:", GlobalState.player_position)

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
	if "pickaxe" in player_stats.equipped_items and player_stats.equipped_items["pickaxe"] != null:
		# ✅ Pickaxe is equipped → Show it
		pickaxe_sprite.visible = true
		pickaxe_sprite.texture = load("res://assets/items/" + player_stats.equipped_items["pickaxe"] + ".png")
	else:
		# ❌ Pickaxe is unequipped → Hide it
		pickaxe_sprite.visible = false
		pickaxe_sprite.texture = null
	# Update input vector for facing direction
	var input_vector: Vector2 = Vector2(
		Input.get_action_strength("walk_right") - Input.get_action_strength("walk_left"),
		Input.get_action_strength("walk_down") - Input.get_action_strength("walk_up")
	)
	
	update_pickaxe_visibility()  # ✅ Ensures visibility is always correct
	
	if input_vector != Vector2.ZERO:
		input_vector = input_vector.normalized()
		GlobalState.update_last_facing_direction(input_vector)
	
	# Save position if changed
	if position != last_position:
		last_position = position
		save_player_position()  # Trigger position save whenever position changes
		
	# Update the swing timer if active
	if swing_timer > 0.0:
		swing_timer -= delta
	
	var velocity: Vector2 = Vector2.ZERO
	var current_direction: String = ""
	
	# Gather movement input
	if Input.is_action_pressed("walk_right"):
		velocity.x += 1
		current_direction = "walk_right"
	if Input.is_action_pressed("walk_left"):
		velocity.x -= 1
		current_direction = "walk_left"
	if Input.is_action_pressed("walk_down"):
		velocity.y += 1
		current_direction = "walk_down"
	if Input.is_action_pressed("walk_up"):
		velocity.y -= 1
		current_direction = "walk_up"
	
	# Normalize movement vector and scale by speed
	if velocity != Vector2.ZERO:
		velocity = velocity.normalized() * speed
	
	# If the player is moving, update last_direction and play the corresponding walk animation (if not swinging)
	if velocity.length() > 0:
		last_direction = current_direction
		if not is_swinging:
			match current_direction:
				"walk_right":
					animated_sprite.play("walk_right")
				"walk_left":
					animated_sprite.play("walk_left")
				"walk_down":
					animated_sprite.play("walk_down")
				"walk_up":
					animated_sprite.play("walk_up")
		# If swinging, we let the swing animation take priority
	else:
		# When idle, use the last_direction to display the correct idle frame
		if not is_swinging:
			match last_direction:
				"walk_right":
					animated_sprite.play("walk_right")
					animated_sprite.frame = 0
				"walk_left":
					animated_sprite.play("walk_left")
					animated_sprite.frame = 0
				"walk_down":
					animated_sprite.play("walk_down")
					animated_sprite.frame = 0
				"walk_up":
					animated_sprite.play("walk_up")
					animated_sprite.frame = 0
				_:
					animated_sprite.play("idle")
	
	# Check for swing input
	if Input.is_action_just_pressed("swing") and swing_timer <= 0.0 and not is_swinging:
		is_swinging = true
		perform_swing()
	
	# If the swing animation has finished playing, clear the swinging state
	if is_swinging and not animated_sprite.is_playing():
		is_swinging = false
	
	# Update movement and position
	self.velocity = velocity
	move_and_slide()
	sync_player_position()

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


# Function to perform the swing animation
func perform_swing():
	# Determine the swing animation direction based on last movement
	var swing_animation = get_swing_animation(last_direction)

	# If a valid direction is found, play the swing animation
	if swing_animation != "":
		animated_sprite.play(swing_animation)
		# Reset the swing cooldown
		swing_timer = swing_cooldown
	else:
		# If no valid direction found, log an error
		is_swinging = false

# Function to return the swing animation based on last movement direction
func get_swing_animation(direction: String) -> String:
	match direction:
		"walk_right":
			return "swing_right"
		"walk_left":
			return "swing_left"
		"walk_down":
			return "swing_down"
		"walk_up":
			return "swing_up"
		_:
			return ""  # No valid direction


# Called when player interacts with a mining node
func mine(ore_type: String, ore_quantity: int):
	if is_swinging:
		return  # Prevent the player from mining while already swinging
	
	# Set the swinging state to true
	is_swinging = true

	# Add ores to the inventory (stored in PlayerStats)
	player_stats.add_item_to_inventory(ore_type, ore_quantity)

	# Gain XP for mining
	var xp_gain = ore_quantity * 10  # Adjust XP per ore
	player_stats.gain_xp("mining", xp_gain)

	# Play mining animation based on the direction the player is facing
	play_mining_animation()

	# Reset the swinging state after the cooldown using await
	await get_tree().create_timer(swing_cooldown).timeout
	is_swinging = false

# Called when player clicks to start automining
func start_automine(ore: Node) -> void:
	if is_swinging or automining:
		return  # Prevent automining if already mining or swinging

	automining = true
	print("⛏️ Automining started")

	# Start the mining process with the given ore
	automine_ore(ore)

# Automine ore function: continue mining until the ore is broken
func automine_ore(ore: Node) -> void:
	# Prevent starting if already destroyed
	if ore.is_destroyed:
		automining = false
		return

	# Start mining animation
	play_mining_animation()

	# Keep mining the ore every frame while it's not broken
	while ore and ore.ore_health > 0:
		if not is_swinging:
			is_swinging = true
			# Trigger the swing action
			ore.mine_ore(self)

		# Wait for swing cooldown to finish before continuing
		await get_tree().create_timer(swing_cooldown).timeout

	# Once the ore is destroyed, stop automining
	automining = false

func get_closest_ore() -> Node:
	# Enable the RayCast2D to check for ores in front of the player
	raycast.enabled = true
	
	# Set the direction of the ray based on the player's last direction
	var direction = Vector2.ZERO
	
	if last_direction == "walk_right":
		direction = Vector2(50, 0)  # Ray points to the right
	elif last_direction == "walk_left":
		direction = Vector2(-50, 0)  # Ray points to the left
	elif last_direction == "walk_down":
		direction = Vector2(0, 50)  # Ray points down
	elif last_direction == "walk_up":
		direction = Vector2(0, -50)  # Ray points up
	
	# Perform the raycast check
	var space_state = get_world_2d().direct_space_state  # Get the 2D space for raycasting (Godot 4)

	# Create PhysicsRayQueryParameters2D
	var ray_query = PhysicsRayQueryParameters2D.new()
	ray_query.from = global_position
	ray_query.to = global_position + direction
	ray_query.exclude = [self]  # Exclude the player from the raycast

	# Perform the raycast
	var result = space_state.intersect_ray(ray_query)

	if result:
		var hit_object = result["collider"]
		if hit_object and hit_object.is_in_group("ore"):  # Check if it's an ore
			return hit_object  # Return the ore node if detected

	return null  # Return null if no ore is found


# Function to play mining animation based on the direction the player is facing
func play_mining_animation():
	# Ensure the correct animation plays based on last direction and ore type
	if last_direction == "walk_right":
		animated_sprite.play("mining_right")  # Play mining animation facing right
	elif last_direction == "walk_left":
		animated_sprite.play("mining_left")  # Play mining animation facing left
	elif last_direction == "walk_down":
		animated_sprite.play("mining_down")  # Play mining animation facing down
	elif last_direction == "walk_up":
		animated_sprite.play("mining_up")  # Play mining animation facing up
	else:
		# Default to right-facing mining animation if no direction is found
		animated_sprite.play("mining_right")

# --- ITEM EQUIP/UNEQUIP FUNCTIONS ---
# Called when an inventory item is clicked to toggle pickaxe equip
func _on_item_button_pressed(item_name: String) -> void:
	print("🖱️ Player clicked on item:", item_name)

	if not player_stats:
		print("❌ ERROR: PlayerStats not found!")
		return

	if not player_stats.inventory.has(item_name):
		print("❌ ERROR: Item not found in inventory:", item_name)
		return

	# Check if the item is already equipped → Unequip it
	if item_name in player_stats.equipped_items.values():
		print("❎ Unequipping:", item_name)
		if player_stats.has_method("unequip_item"):
			player_stats.unequip_item(item_name)
	else:
		print("✅ Equipping:", item_name)
		if player_stats.has_method("equip_item"):
			player_stats.equip_item(item_name)

	update_inventory_panel()
	update_pickaxe_visibility()  # ✅ Ensure the pickaxe shows/hides immediately


func update_pickaxe_visibility():
	var equipped_weapon = GlobalState.equipped_items.get("weapon", null)

	# ✅ Ensure pickaxe visibility syncs correctly
	if equipped_weapon and GlobalState.get_item_type(equipped_weapon) == "pickaxe":
		pickaxe_sprite.visible = true
		pickaxe_sprite.texture = load("res://assets/items/" + equipped_weapon + ".png")
	else:
		pickaxe_sprite.visible = false
		pickaxe_sprite.texture = null

	# ✅ Force UI refresh
	await get_tree().process_frame

	if inventory_panel == null:
		inventory_panel = get_tree().get_root().find_child("InventoryPanel", true, false)


func _on_item_picked_up(item_name: String, item_type: String):
	print("Item picked up:", item_name)

	# ✅ If item type is empty or "unknown", get the correct type from GlobalState
	if item_type == "" or item_type == "unknown":
		item_type = GlobalState.get_item_type(item_name)

	add_item_to_inventory(item_name, item_type)
	sync_inventory_with_global_state()

	# ✅ Ensure UI updates immediately
	if inventory_panel:
		print("🔄 Forcing Inventory UI Update after item pickup...")
		inventory_panel.update_inventory_panel()

func get_inventory_panel():
	var ui_root = get_tree().get_root().find_child("MainUI", true, false)
	if ui_root:
		var inventory = ui_root.find_child("InventoryPanel", true, false)
		if inventory:
			print("✅ InventoryPanel found dynamically!")
			return inventory
	print("❌ ERROR: InventoryPanel NOT found!")
	return null


# Function to add the item to the inventory
func add_item_to_inventory(item_name: String, item_type: String):
	if item_name in player_stats.inventory:
		if typeof(player_stats.inventory[item_name]) == TYPE_DICTIONARY:
			player_stats.inventory[item_name]["quantity"] += 1  # ✅ Increase quantity
		else:
			print("⚠️ Fixing inventory format for:", item_name)
			player_stats.inventory[item_name] = {"quantity": 1, "type": item_type}  # ✅ Ensure correct format
	else:
		player_stats.inventory[item_name] = {"quantity": 1, "type": item_type}  # ✅ Set correct format on first pickup

	print("📌 Updated Inventory:", player_stats.inventory)  # Debugging


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


# Function to sync player stats (to be implemented properly)
func sync_player_stats() -> void:
	print("Syncing player stats...")  # Placeholder
	# Add code to sync data with GlobalState or a save system

# Function to update the inventory UI immediately
# ✅ Function exists inside Inventory.gd
func update_inventory_ui():
	if inventory_panel:
		print("✅ Updating Inventory UI...")
		if inventory_panel.has_method("update_inventory_ui"):
			inventory_panel.update_inventory_ui()
		else:
			print("❌ ERROR: InventoryPanel does not have update_inventory_ui()!")
	else:
		print("❌ ERROR: InventoryPanel not found in Player.gd!")


func apply_loaded_facing_direction():
	# Verify the AnimatedSprite2D node exists
	if not $AnimatedSprite2D:
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
	$AnimatedSprite2D.animation = new_anim
	$AnimatedSprite2D.frame = 0
	last_direction = new_anim  # Store the loaded direction so the idle branch uses it

# Equip the item in the player inventory
func equip_item(item_name: String):
	print("🖱️ Player clicked on item:", item_name)

	# Check if the item exists in the inventory
	if not player_stats.inventory.has(item_name):
		print("❌ ERROR: Item not found in inventory:", item_name)
		return

	# Check if the item is already equipped → Unequip it
	if item_name in player_stats.equipped_items.values():
		print("❎ Unequipping:", item_name)
		if player_stats.has_method("unequip_item"):
			player_stats.unequip_item(item_name)
	else:
		print("✅ Equipping:", item_name)
		if player_stats.has_method("equip_item"):
			player_stats.equip_item(item_name)

	# Update the UI immediately
	update_inventory_panel()
	update_pickaxe_visibility()  # Ensure the pickaxe is shown or hidden immediately
	print("🛠 Debugging equipped items:", GlobalState.equipped_items)

# Unequip the item from the player inventory
func unequip_item(slot_type: String):
	var item = GlobalState.equipped_items.get(slot_type, null)
	if item:
		print("❎ Unequipping:", item, "from", slot_type)

		# ✅ Make sure the item is returned to inventory
		if GlobalState.inventory.has(item):
			GlobalState.inventory[item]["quantity"] += 1
		else:
			GlobalState.inventory[item] = {"quantity": 1, "type": GlobalState.get_item_type(item)}

		# ✅ Remove the item from equipped slot
		GlobalState.equipped_items[slot_type] = null
		GlobalState.save_all_data()

		# ✅ Update Inventory UI
		var inventory_panel = get_inventory_panel()
		if inventory_panel:
			print("🔄 Updating Inventory UI after unequip...")
			inventory_panel.update_inventory_ui()
		else:
			print("❌ ERROR: InventoryPanel not found during unequip!")

	print("✅ Slot", slot_type, "is now empty.")


func equip_item_from_inventory(item_name: String):
	print("✅ Attempting to equip from inventory:", item_name)

	# Make sure the item exists in the inventory
	if not GlobalState.inventory.has(item_name):
		print("❌ ERROR: Item not found in inventory:", item_name)
		return

	# Determine the correct slot
	var item_type = GlobalState.get_item_type(item_name)
	var slot_type = get_slot_for_item_type(item_type)

	if slot_type == "":
		print("❌ ERROR: No valid slot for", item_name)
		return

	# Remove the item from inventory before equipping
	GlobalState.inventory.erase(item_name)

	# Equip the item in the correct slot
	GlobalState.equipped_items[slot_type] = item_name
	GlobalState.save_all_data()

	# Update UI properly
	var armor_panel = get_inventory_panel()
	if armor_panel:
		print("✅ InventoryPanel found, updating UI after equipping...")
		armor_panel.update_inventory()
	else:
		print("❌ ERROR: InventoryPanel not found after equipping!")

	# Update Armor Panel UI
	var armor_ui = get_tree().get_first_node_in_group("armor_ui")
	if armor_ui:
		print("✅ Updating ArmorPanel UI for equipped item...")
		armor_ui.equip_item_from_inventory(slot_type, item_name)
	else:
		print("❌ ERROR: ArmorPanel UI not found!")

	print("✅ Finished equipping:", item_name)



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

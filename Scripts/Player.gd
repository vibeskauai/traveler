extends CharacterBody2D

var speed = 65  # Walking speed
var swing_cooldown = 0.5  # Cooldown time for swing in seconds
var swing_timer = 0.0  # Timer to track cooldown for swing animation

# Reference to AnimatedSprite2D node
@onready var sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer
@onready var player_stats = get_node("/root/PlayerStats")  # Assuming PlayerStats is a singleton or part of the scene
@onready var raycast = $RayCast2D  # Access the RayCast2D node
@onready var global_state = GlobalState  # Reference to the GlobalState singleton
@onready var pickaxe_sprite = $PickaxeSprite
@onready var inventory_panel = get_tree().get_first_node_in_group("inventory_panel")  # ✅ Uses group instead of fixed path
@onready var armor_panel = get_tree().get_first_node_in_group("armor_ui")  # Find Armor UI dynamically
@onready var pickaxe_hitbox := $PickaxeSprite/hitbox
@onready var main_ui = get_tree().get_first_node_in_group("main_ui")

var is_mining: bool = false  # Track if the player is currently mining
var target_ore: Node = null  # The ore the player is mining

var equipped_item = null  # Currently equipped item
var automining = false  # Track if the player is automining

# Variable to store last movement direction animation name
var last_direction = ""  # This can be "walk_right", "walk_left", "walk_down", "walk_up"
var last_position: Vector2 = Vector2(0, 0)  # Store last position to detect changes
# Track if the swing animation is already playing
var is_swinging = false

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
	if is_mining and target_ore and target_ore.is_inside_tree():
		mine_target_ore()

	# Update input vector for facing direction
	var input_vector: Vector2 = Vector2(
		Input.get_action_strength("walk_right") - Input.get_action_strength("walk_left"),
		Input.get_action_strength("walk_down") - Input.get_action_strength("walk_up")
	)
	
	update_pickaxe_visibility()  # Ensures visibility is always correct
	
	if input_vector != Vector2.ZERO:
		input_vector = input_vector.normalized()
		GlobalState.update_last_facing_direction(input_vector)
	
	# Save position if changed
	if position != last_position:
		last_position = position
		save_player_position()  # Trigger position save whenever position changes

	var velocity: Vector2 = Vector2.ZERO
	var current_direction: String = ""
	
	# If swinging, stop movement (set velocity to zero)
	if is_swinging:
		velocity = Vector2.ZERO
	else:
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
	if velocity.length() > 0 and not is_swinging:
		last_direction = current_direction

		# Check if the pickaxe is equipped by referencing GlobalState.equipped_items
		var is_pickaxe_equipped = "pickaxe" in GlobalState.equipped_items  # Check if "pickaxe" is in the equipped items list
		
		if is_pickaxe_equipped:
			# Play the walking with pickaxe animations
			match current_direction:
				"walk_right":
					animation_player.play("walk_right_with_pickaxe")
				"walk_left":
					animation_player.play("walk_left_with_pickaxe")
				"walk_down":
					animation_player.play("walk_down_with_pickaxe")
				"walk_up":
					animation_player.play("walk_up_with_pickaxe")
		else:
			# Play regular walking animations without the pickaxe
			match current_direction:
				"walk_right":
					animation_player.play("walk_right")
				"walk_left":
					animation_player.play("walk_left")
				"walk_down":
					animation_player.play("walk_down")
				"walk_up":
					animation_player.play("walk_up")
	# If swinging, we let the swing animation take priority
	elif not is_swinging:
		# When idle, use the last_direction to display the correct animation (play first frame of last direction)
		match last_direction:
			"walk_right":
				animation_player.play("walk_right")
				animation_player.seek(0)  # Ensures we start from the first frame of the walk_right animation
			"walk_left":
				animation_player.play("walk_left")
				animation_player.seek(0)  # Ensures we start from the first frame of the walk_left animation
			"walk_down":
				animation_player.play("walk_down")
				animation_player.seek(0)  # Ensures we start from the first frame of the walk_down animation
			"walk_up":
				animation_player.play("walk_up")
				animation_player.seek(0)  # Ensures we start from the first frame of the walk_up animation
	
	# Check for swing input
	if Input.is_action_just_pressed("swing") and swing_timer <= 0.0 and not is_swinging:
		is_swinging = true
		perform_swing()

		# Play the swing animation based on the current walking direction with pickaxe
		var swing_anim = get_swing_animation(last_direction)
		animation_player.play(swing_anim)
	
	# Swing logic (if any)
	if swing_timer > 0.0:
		swing_timer -= delta
	
	# If the swing animation has finished playing, return to walking animation and reset to the first frame
	if is_swinging and not animation_player.is_playing():
		is_swinging = false

		# After the swing is done, return to the walking animation in the last direction with pickaxe
		if "pickaxe" in GlobalState.equipped_items:
			match last_direction:
				"walk_right":
					animation_player.play("walk_right_with_pickaxe")
				"walk_left":
					animation_player.play("walk_left_with_pickaxe")
				"walk_down":
					animation_player.play("walk_down_with_pickaxe")
				"walk_up":
					animation_player.play("walk_up_with_pickaxe")
			animation_player.seek(0)  # Reset to the first frame of the walking animation
		else:
			match last_direction:
				"walk_right":
					animation_player.play("walk_right")
				"walk_left":
					animation_player.play("walk_left")
				"walk_down":
					animation_player.play("walk_down")
				"walk_up":
					animation_player.play("walk_up")
			animation_player.seek(0)  # Reset to the first frame of the walking animation
	
	# Update movement and position
	self.velocity = velocity
	move_and_slide()
	sync_player_position()


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

# Function to ensure hitbox is active during swing
func perform_swing():
	var swing_animation = get_swing_animation(last_direction)

	if swing_animation != "":
		# Play the correct swing animation
		animation_player.play(swing_animation)
		swing_timer = swing_cooldown  # Reset swing timer

		# Ensure the pickaxe hitbox is enabled during the swing
		var pickaxe_hit_area = $PickaxeSprite/hitbox  # Assuming hitbox is an Area2D

		if pickaxe_hit_area:
			pickaxe_hit_area.monitoring = true  # Ensure monitoring is enabled

			# Check for interaction with ores using the hit area
			var ore = detect_ore_in_swing_area(pickaxe_hit_area)
			if ore:
				print("⛏️ Ore detected during swing:", ore.name)  # Debug output

				# Start mining without passing arguments
				ore.start_mining()


# Function to return the swing animation based on the last movement direction
func get_swing_animation(direction: String) -> String:
	match direction:
		"walk_right":
			return "swing_right_with_pickaxe"
		"walk_left":
			return "swing_left_with_pickaxe"
		"walk_down":
			return "swing_down_with_pickaxe"  # Ensure the correct swing animation for downward direction
		"walk_up":
			return "swing_up_with_pickaxe"
		_:
			return ""  # No valid direction or default to empty string

# Function to detect if an ore is in the swing area (collision detection)
func detect_ore_in_swing_area(hitbox: Area2D) -> Node:
	var collided_areas = hitbox.get_overlapping_areas()

	print("Checking for ores in hitbox")  # Debug message

	for area in collided_areas:
		if area.is_in_group("ores"):  # Updated to check "ores" group
			print("Detected ore:", area.get_parent().name)  # Debug output
			return area.get_parent()  # Return the ore node
	return null

# --- Auto-mining Section ---
func start_auto_mining():
	if not target_ore:
		return

	is_mining = true
	print("⛏️ Auto-mining started on", target_ore.ore_type)

	mine_target_ore()

func mine_target_ore():
	if not target_ore or not is_mining:
		return

	var equipped_path = PlayerStats.get_equipped_item("pickaxe")
	if equipped_path == "":
		print("❌ No pickaxe equipped!")
		return

	var equipped_pickaxe = load(equipped_path)
	if not (equipped_pickaxe and equipped_pickaxe is ItemResource):
		print("❌ Failed to load equipped pickaxe resource!")
		return

	target_ore.mine_ore(equipped_pickaxe, self)
	animation_player.play("mine_swing")

	await get_tree().create_timer(0.5).timeout  # Delay for auto-mining loop
	if is_mining:
		mine_target_ore()

func _on_pickaxe_hit(area):
	if area and area.is_in_group("ores"):
		var ore = area.get_parent()
		var equipped_path = PlayerStats.get_equipped_item("pickaxe")

		if equipped_path != "":
			var equipped_pickaxe = load(equipped_path)
			if equipped_pickaxe and equipped_pickaxe is ItemResource:
				print("⛏️ Mining with:", equipped_pickaxe.item_name)
				ore.mine_ore(equipped_pickaxe, self)
			else:
				print("❌ Failed to load pickaxe resource:", equipped_path)
		else:
			print("❌ No pickaxe equipped!")

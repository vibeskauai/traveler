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
@onready var armor_panel = get_tree().get_first_node_in_group("armor_ui")  # Find Armor UI dynamically
@onready var pickaxe_hitbox := $PickaxeSprite/hitbox
@onready var animation_player := $AnimationPlayer
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
	
	update_pickaxe_visibility()  # ✅ Ensures visibility is always correct
	
	if input_vector != Vector2.ZERO:
		input_vector = input_vector.normalized()
		GlobalState.update_last_facing_direction(input_vector)
	
	# Save position if changed
	if position != last_position:
		last_position = position
		save_player_position()  # Trigger position save whenever position changes

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
	
		# Swing logic (if any)
	if swing_timer > 0.0:
		swing_timer -= delta
	
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
	var pickaxe_name = player_stats.equipped_items.get("weapon", "")

	if has_node("PickaxeSprite"):
		var pickaxe_sprite = get_node("PickaxeSprite")

		if pickaxe_name and pickaxe_name != "":

			# **Ensure sprite texture is actually assigned**
			var pickaxe_texture = load("res://assets/items/" + pickaxe_name + ".png")

			if pickaxe_texture:
				pickaxe_sprite.texture = pickaxe_texture
				pickaxe_sprite.visible = true
			else:
				print("❌ [Player] ERROR: Pickaxe texture is missing for:", pickaxe_name)

		else:
			pickaxe_sprite.visible = false

	else:
		print("❌ [Player] ERROR: PickaxeSprite node is missing in Player!")


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
		inventory_panel.update_inventory_ui()
	else:
		print("❌ ERROR: inventory_panel is NULL! Searching scene tree...")
	
	# Try dynamically finding it
	inventory_panel = get_tree().get_first_node_in_group("inventory_ui")

	if inventory_panel:
		print("✅ InventoryPanel found dynamically, updating UI!")
		inventory_panel.update_inventory_ui()
	else:
		print("❌ STILL ERROR: InventoryPanel could not be found!")


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
# ✅ EQUIP AN ITEM (Calls PlayerStats)
func on_item_equipped(slot_type, item_name):
	if slot_type == "weapon":
		update_pickaxe_visibility()

func on_item_unequipped(slot_type, item_name):
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
	

# Called when the player swings the pickaxe
func perform_swing():
	var swing_animation = get_swing_animation(last_direction)

	if swing_animation != "":
		animated_sprite.play(swing_animation)
		swing_timer = swing_cooldown
		
		# Check for ore interaction on swing
		var pickaxe_hit_area = $PickaxeSprite/hitbox
		if pickaxe_hit_area:
			var ore = detect_ore_in_swing_area(pickaxe_hit_area)
			if ore:
				print("⛏️ Ore detected during swing:", ore.name)  # Debug output
				ore.mine_ore(self)  # Call the mine_ore function from OreNode
	else:
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

	var equipped_pickaxe = PlayerStats.get_equipped_item("pickaxe")
	if not equipped_pickaxe:
		print("❌ No pickaxe equipped!")
		return

	target_ore.mine_ore(equipped_pickaxe, self)
	animation_player.play("mine_swing")

	await get_tree().create_timer(0.5).timeout  # Delay for auto-mining
	if is_mining:
		mine_target_ore()

# Detects collision with ores during swing
func _on_pickaxe_hit(area):
	if area and area.is_in_group("ore"):
		var ore = area.get_parent()
		var equipped_pickaxe = PlayerStats.get_equipped_item("pickaxe")

		if equipped_pickaxe:
			print("⛏️ Mining with:", equipped_pickaxe)
			ore.mine_ore(equipped_pickaxe, self)  # Send pickaxe name and player reference

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

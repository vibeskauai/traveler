extends Node

@onready var player = get_tree().get_first_node_in_group("player")
@onready var inventory_panel = get_tree().get_first_node_in_group("inventory_panel")  # ✅ Uses group instead of fixed path
@onready var player_stats = get_node("/root/PlayerStats")  # Access PlayerStats for syncing equipped items
var last_animation_played: String = "idle_down"  # Default to "idle" if nothing is set

signal new_game_started(new_position: Vector2)
var is_game_loaded: bool = false
# Player-related data
var player_position : Vector2 = Vector2(43, -42)  # Default starting position (Vector2 type)
var inventory: Array = []
var player_xp = 0  # Player experience points
var total_level = 1  # Starting level
var health = 100  # Player health

# NEW: Last facing direction 
var last_facing_direction = Vector2(0, 1)  # Default value to "down" (0,1)

# Skill progression data (Mining, Herbalism, Combat)
var mining_xp = 0
var herbalism_xp = 0
var combat_xp = 0

# NEW: Skill level data for each skill
var mining_level = 1
var herbalism_level = 1
var combat_level = 1

var equipped_items = {
	"weapon": null,
	"helm": null,
	"chest": null,
	"legs": null,
	"shield": null,
	"pickaxe": null  # ✅ Ensure pickaxe is also considered
}

# ✅ Define all item types here
var item_data = {
	"Hollowed Pickaxe": { "type": "pickaxe" },
	"Copper Ore": { "type": "resource" },
	"Silver Ore": { "type": "resource" },
	"Gold Ore": { "type": "resource" },
	"Rune Ore": { "type": "resource" },
	"Dragon Ore": { "type": "resource" },
}

var item_types = {
	"Hollowed Pickaxe": "pickaxe",
	"Copper Ore": "resource",
	"Silver Ore": "resource",
	"Gold Ore": "resource",
	"Rune Ore": "resource",
	"Dragon Ore": "resource"
}

# ✅ Function to get the correct item type
func get_item_type(item_name: String) -> String:
	if item_types.has(item_name):
		return item_types[item_name]
	return "unknown"  # Default to unknown if not defined

# Game progress data
var has_spoken_to_durmil = false
var has_upgraded_pickaxe = false

# Autosave Timer
var autosave_timer : Timer

var is_new_game: bool = false
# Path for the save file
var save_file_path = "user://game_data.json"

# Called when the game starts
func _ready():

	if not has_meta("mined_ores"):
		set_meta("mined_ores", {})  # Initialize an empty dictionary if it's not found
	autosave_timer = Timer.new()
	add_child(autosave_timer)
	autosave_timer.wait_time = 10  # Set autosave interval to 10 seconds
	autosave_timer.one_shot = false  # Repeat after each interval
	autosave_timer.connect("timeout", Callable(self, "_on_autosave_timeout"))
	autosave_timer.start()

	# Load saved game data when the game starts
	load_game_data()

func _process(delta):
	if Input.is_action_just_pressed("new_game"):
		new_game()  # This calls your new_game() function and resets all data

# Function to start a new game by resetting all game data
func new_game():
	print("🚀 Starting a new game. Resetting data...")

	# ✅ Prevents old positions from being saved before reload
	is_new_game = true

	# Remove the old save file to avoid loading old data
	if FileAccess.file_exists(save_file_path):
		print("🗑️ Removing old save file...")
		DirAccess.remove_absolute(save_file_path)

	# ✅ Set the default new game player position
	player_position = Vector2(43, -42)
	print("✅ New default position set:", player_position)

	# Reset all other game data
	inventory = []
	player_xp = 0
	total_level = 1
	health = 100
	last_facing_direction = Vector2(0, 0)
	
	mining_xp = 0
	herbalism_xp = 0
	combat_xp = 0
	mining_level = 1
	herbalism_level = 1
	combat_level = 1

	equipped_items = {
		"weapon": null,
		"armor": null,
		"pickaxe": null
	}

	has_spoken_to_durmil = false
	has_upgraded_pickaxe = false
	mined_ores.clear()

	# ✅ Immediately save the new game state
	print("💾 Saving new game state...")
	save_all_data()
	
	print("✅ New game created and saved with default player position:", player_position)

# Function to update player position
func update_player_position(new_position: Vector2):
	player_position = new_position
	save_all_data()  # Automatically save whenever position is updated

# Save all game data to a file
func save_all_data():

	# Convert last facing direction into a string format for saving
	var last_facing_str = str(last_facing_direction.x) + "," + str(last_facing_direction.y)

	# Convert inventory to a savable format (path and quantity)
	var serialized_inventory = []
	for entry in inventory:
		if entry.has("path") and entry.has("quantity"):
			serialized_inventory.append({
				"path": entry["path"],
				"quantity": entry["quantity"]
			})

	# Prepare the full save data dictionary
	var data = {
		"player_position": str(player_position.x) + "," + str(player_position.y),
		"last_animation_played": GlobalState.last_animation_played,
		"inventory": serialized_inventory,
		"equipped_items": equipped_items,
		"player_xp": player_xp,  # Ensure player XP is included
		"total_level": total_level,
		"health": health,
		"mining_xp": mining_xp,  # Ensure mining XP is included
		"herbalism_xp": herbalism_xp,  # Ensure herbalism XP is included
		"combat_xp": combat_xp,  # Ensure combat XP is included
		"last_facing_direction": last_facing_str,
		"mined_ores": mined_ores,
		"has_spoken_to_durmil": has_spoken_to_durmil,
		"has_upgraded_pickaxe": has_upgraded_pickaxe
	}

	# Convert the data dictionary to a JSON string
	var json = JSON.new()
	var json_data = json.stringify(data)

	# Write the JSON data to a file
	var file = FileAccess.open(save_file_path, FileAccess.WRITE)
	if file:
		file.store_string(json_data)
		file.close()

# Load all game data from a file
# Function to load all game data from the file
func load_game_data():
	if not FileAccess.file_exists(save_file_path):
		print("⚠️ No save file found, loading defaults.")
		return

	var file = FileAccess.open(save_file_path, FileAccess.READ)
	if file:
		var json_data = file.get_as_text()
		var json = JSON.new()
		var parse_result = json.parse(json_data)

		if parse_result == OK:
			var data = json.get_data()

			# Load Player Position
			var position_string = data.get("player_position", "0,0")
			var position_array = position_string.split(",")
			player_position = Vector2(float(position_array[0]), float(position_array[1]))

			# Load Last Facing Direction
			var facing_string = data.get("last_facing_direction", "0,1")
			var facing_array = facing_string.split(",")
			last_facing_direction = Vector2(float(facing_array[0]), float(facing_array[1]))
			print("↔️ Loaded last facing direction from save:", last_facing_direction)

			# Load Equipped Items
			equipped_items = data.get("equipped_items", {})
			if equipped_items == null:
				equipped_items = {
					"weapon": null, "helm": null, "chest": null,
					"legs": null, "shield": null, "pickaxe": null
				}

			# Load Inventory as resource-based entries
			inventory.clear()
			var saved_inventory = data.get("inventory", [])
			for entry in saved_inventory:
				if entry.has("path") and entry.has("quantity"):
					inventory.append({
						"path": entry["path"],
						"quantity": entry["quantity"]
					})
			print("📦 [GlobalState] Loaded Inventory from Save:", inventory)

			# Load XP and Levels
			player_xp = data.get("player_xp", 0)
			total_level = data.get("total_level", 1)
			health = data.get("health", 100)

			# Load skill XP and levels
			mining_xp = data.get("mining_xp", 0)
			herbalism_xp = data.get("herbalism_xp", 0)
			combat_xp = data.get("combat_xp", 0)

			# Sync loaded XP to SkillStats (this is crucial for correct level-up handling)
			SkillStats.mining_xp = mining_xp
			SkillStats.herbalism_xp = herbalism_xp
			SkillStats.combat_xp = combat_xp

			# Ensure levels are updated after loading XP values
			SkillStats.update_levels()  # Update levels based on loaded XP

			# Load Mined Ores
			mined_ores = data.get("mined_ores", {})

			# Remove mined ore nodes from the scene
			var ores = get_tree().get_nodes_in_group("ores")
			if ores:
				for node in ores:
					if node is StaticBody2D and node.name.begins_with("CopperNode"):
						var position_str = str(node.global_transform.origin.x) + "," + str(node.global_transform.origin.y)
						if mined_ores.has(position_str):
							node.queue_free()

		file.close()
	else:
		print("⚠️ Failed to open save file.")

	GlobalState.is_new_game = false

	# Update player position after load
	var root = get_tree().get_root()
	if root.has_node("TheCrossroads/Player"):
		var player = root.get_node("TheCrossroads/Player")
		player.call_deferred("set_global_position", player_position)
		player.call_deferred("update_pickaxe_visibility")
		print("✅ Player position and appearance updated after game load!")

	# Update player appearance after load
	if root.has_node("TheCrossroads/Player"):
		var player = root.get_node("TheCrossroads/Player")
		player.call_deferred("update_pickaxe_visibility")
		print("✅ Player visibility updated after game load!")



# Function for autosave (called every interval)
func _on_autosave_timeout():
	save_all_data()  # Save data

# Sync player stats (XP, level) with PlayerStats.gd
func sync_player_stats():
	GlobalState.equipped_items = equipped_items  # Save equipped items
	GlobalState.player_xp = player_xp
	GlobalState.total_level = total_level
	GlobalState.health = health
	GlobalState.mining_xp = mining_xp
	GlobalState.herbalism_xp = herbalism_xp
	GlobalState.combat_xp = combat_xp
	GlobalState.inventory = inventory  # Sync inventory as well


# NEW: Function to update the last facing direction and save
func update_last_facing_direction(new_direction: Vector2):
	last_facing_direction = new_direction
	save_all_data()  # ✅ Auto-save when facing direction changes

func update_equipped_items(slot_type, item_name):
	# Syncs equipped items with GlobalState
	equipped_items[slot_type] = item_name
	save_all_data()

func update_inventory(item_path: String, add_item: bool):
	if item_path == "":
		print("❌ Invalid item path.")
		return

	if add_item:
		# Try to find the item already in inventory
		for entry in inventory:
			if entry.path == item_path:
				entry.quantity += 1
				save_all_data()
				return

		# If item not found, add new entry
		inventory.append({ "path": item_path, "quantity": 1 })
	else:
		# Remove item from inventory (all copies)
		for i in inventory.size():
			if inventory[i].path == item_path:
				inventory.remove_at(i)
				break

	save_all_data()

var mined_ores = {}  # Dictionary to track mined ores

# Save the mined ore state and remove the node
func save_mined_ore(position: Vector2, ore_type: String, ore_node: Node):
	var position_str = str(position.x) + "," + str(position.y)

	# Debug: Print the current state of mined_ores before saving
	print("🔄 Saving mined ore at position:", position_str, "with type:", ore_type)

	# Save the ore type at the position
	mined_ores[position_str] = ore_type

	# Save the global data persistently
	save_all_data()  # Save the global data persistently
	print("✅ Mined ore saved successfully.")

	# Ensure the node is removed after saving
	if ore_node:
		print("✅ Removing ore node:", ore_node.name)
		ore_node.queue_free()  # Remove the ore node from the scene
		print("✅ Ore node removed from the scene.")


# Remove mined ores from TheCrossroads scene
func remove_mined_ores(the_crossroads: Node):
	# Ensure the_crossroads is valid
	if the_crossroads == null:
		print("❌ TheCrossroads node is null!")
		return

	# Loop through all child nodes in TheCrossroads scene
	for node in the_crossroads.get_children():
		if node.name.begins_with("CopperNode"):  # Target ore nodes like CopperNode1, CopperNode2, etc.
			
			# Debug: Print the node type
			print("Node Type: ", node, "Type:", node.get_class())

			# Check if the node is a StaticBody2D (since global_position is not available directly)
			if node is StaticBody2D:
				# Get position from transform.origin for StaticBody2D
				var position_str = str(node.global_transform.origin.x) + "," + str(node.global_transform.origin.y)

				# Check if this ore has been mined (using GlobalState's mined_ores)
				if mined_ores.has(position_str):
					print("❌ Ore at position", node.global_transform.origin, "is already mined, removing.")
					
					# Save the ore before removing it
					save_mined_ore(node.global_transform.origin, "copper_ore", node)  # Save and remove the node

					continue  # Skip processing this ore since it's mined

				print("✅ Ore at position", node.global_transform.origin, "is not mined.")
			else:
				print("❌ Node is not of type StaticBody2D and doesn't have global_position:", node.name)

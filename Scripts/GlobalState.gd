extends Node


signal new_game_started(new_position: Vector2)
# Player-related data
var player_position : Vector2 = Vector2(43, -42)  # Default starting position (Vector2 type)
var inventory = {}  # Inventory will be a dictionary where items are stored
var player_xp = 0  # Player experience points
var total_level = 1  # Starting level
var health = 100  # Player health

# NEW: Last facing direction (defaulting to facing right)
var last_facing_direction : Vector2 = Vector2(0, 1)

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

# Global data variables for storing mined ores (positions and ore types)
var mined_ores = {}  # Key: position (Vector2), Value: ore_type

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
	inventory = {}
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
	var save_dict = {
		"inventory": inventory,
		"equipped_items": equipped_items  # ✅ Ensure equipped items are saved
	}

	# Convert last facing direction to string in "x,y" format
	var last_facing_str = str(last_facing_direction.x) + "," + str(last_facing_direction.y)

	# Prepare the data dictionary to save
	var data = {
		"player_position": str(player_position.x) + "," + str(player_position.y),
		"inventory": inventory,
		"equipped_items": equipped_items,  # ✅ Include equipped items
		"player_xp": player_xp,
		"total_level": total_level,
		"health": health,
		"mining_xp": mining_xp,
		"herbalism_xp": herbalism_xp,
		"combat_xp": combat_xp,
		"last_facing_direction": last_facing_str,
		"has_spoken_to_durmil": has_spoken_to_durmil,
		"has_upgraded_pickaxe": has_upgraded_pickaxe
	}

	# Convert the data to a JSON string
	var json = JSON.new()
	var json_data = json.stringify(data)

	# Write the JSON data to the save file
	var file = FileAccess.open(save_file_path, FileAccess.WRITE)
	if file:
		file.store_string(json_data)
		file.close()


# Load all game data from a file
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

			# ✅ Load Player Position
			var position_string = data.get("player_position", "0,0")
			var position_array = position_string.split(",")
			player_position = Vector2(float(position_array[0]), float(position_array[1]))
			
			# ✅ Declare Facing Direction Variable **Before Use**
			var loaded_facing_direction = Vector2.ZERO

			# ✅ Load Last Facing Direction
			var facing_string = data.get("last_facing_direction", "0,1")  # Default to left
			var facing_array = facing_string.split(",")
			last_facing_direction = Vector2(float(facing_array[0]), float(facing_array[1]))
			print("↔️ Loaded last facing direction from save:", last_facing_direction)
			
				  # Ensure it does not load (0,0), which is an invalid direction
			if loaded_facing_direction == Vector2.ZERO:
				last_facing_direction = Vector2(0, 1)  # ✅ Default to DOWN (0,1)
			else:
				last_facing_direction = loaded_facing_direction
				
			# ✅ **Load Equipped Items Properly**
			equipped_items = data.get("equipped_items", equipped_items)
			if equipped_items == null:
				equipped_items = { "weapon": null, "helm": null, "chest": null, "legs": null, "shield": null, "pickaxe": null }


			# ✅ Load Other Game Data
			inventory = data.get("inventory", {})
			equipped_items = data.get("equipped_items", equipped_items)
			player_xp = data.get("player_xp", 0)
			total_level = data.get("total_level", 1)
			health = data.get("health", 100)
			mining_xp = data.get("mining_xp", 0)
			herbalism_xp = data.get("herbalism_xp", 0)
			combat_xp = data.get("combat_xp", 0)
			has_spoken_to_durmil = data.get("has_spoken_to_durmil", false)
			has_upgraded_pickaxe = data.get("has_upgraded_pickaxe", false)

		else:
			print("❌ Error parsing saved data: ", json.get_error_message())

		file.close()
	else:
		print("⚠️ Failed to open save file.")

	# ✅ Reset `is_new_game` AFTER loading is complete
	GlobalState.is_new_game = false

	# ✅ Apply the player's new position after the game loads
	var root = get_tree().get_root()
	if root.has_node("TheCrossroads/Player"):
		var player = root.get_node("TheCrossroads/Player")
		player.call_deferred("set_global_position", player_position)
		print("✅ Player position updated after game load:", player_position)

	# ✅ **Apply Equipped Items After Loading**
	if get_tree().get_root().has_node("TheCrossroads/Player"):
		var player = get_tree().get_root().get_node("TheCrossroads/Player")
		player.call_deferred("update_pickaxe_visibility")  # ✅ Ensure player updates pickaxe visibility
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

# Save ore positions and states when ores are mined
func save_mined_ore(position: Vector2, ore_type: String):
	# Save the mined ore's position and type
	mined_ores[position] = ore_type
	print("🪨 Ore saved: ", ore_type, " at position ", position)

# Check if an ore has already been mined based on position
func is_ore_mined(position: Vector2) -> bool:
	return mined_ores.has(position)

# Sync mined ores with the save system (call this function to save the global state)
func sync_mined_ores():
	# Here, you can save the mined_ores dictionary to a file or database
	# For simplicity, let's just print it
	print("Mined ores saved:", mined_ores)

# Load saved mined ores from file or a saved state (You'd implement this based on your save/load system)
func load_mined_ores():
	# Load data from a file or database. For now, we're just initializing it
	# In a real game, you'd use a save system like JSON or similar
	print("Mined ores loaded:", mined_ores)

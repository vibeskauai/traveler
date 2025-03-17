extends Node

# Player-related data
var player_position : Vector2 = Vector2(0, 0)  # Default starting position (Vector2 type)
var inventory = {}  # Inventory will be a dictionary where items are stored
var player_xp = 0  # Player experience points
var total_level = 1  # Starting level
var health = 100  # Player health

# NEW: Last facing direction (defaulting to facing right)
var last_facing_direction : Vector2 = Vector2.RIGHT

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
	"armor": null,
	"pickaxe": null
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
# Player data
# Path for the save file
var save_file_path = "user://game_data.json"

# Called when the game starts

	# Initialize autosave functionality
func _ready():
	autosave_timer = Timer.new()
	add_child(autosave_timer)
	autosave_timer.wait_time = 10  # Set autosave interval to 10 seconds
	autosave_timer.one_shot = false  # Repeat after each interval
	autosave_timer.connect("timeout", Callable(self, "_on_autosave_timeout"))
	autosave_timer.start()

	# Load saved game data when the game starts
	load_game_data()

# Function to update player position
func update_player_position(new_position: Vector2):
	player_position = new_position
	save_all_data()  # Automatically save whenever position is updated

# Save all game data to a file
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
# Load all game data from a file
func load_game_data():
	var file = FileAccess.open(save_file_path, FileAccess.READ)
	if file:
		var json_data = file.get_as_text()
		var json = JSON.new()
		var parse_result = json.parse(json_data)
		if parse_result == OK:
			var data = json.get_data()  # Get parsed data
			# Load player position
			var position_string = data.get("player_position", "0,0")
			var position_array = position_string.split(",")
			player_position = Vector2(float(position_array[0]), float(position_array[1]))

			# Load other game data
			inventory = data.get("inventory", {})
			equipped_items = data.get("equipped_items", equipped_items)  # ✅ Load equipped items
			player_xp = data.get("player_xp", 0)
			total_level = data.get("total_level", 1)
			health = data.get("health", 100)
			mining_xp = data.get("mining_xp", 0)
			herbalism_xp = data.get("herbalism_xp", 0)
			combat_xp = data.get("combat_xp", 0)

			# Load last facing direction
			var facing_string = data.get("last_facing_direction", "1,0")
			var facing_array = facing_string.split(",")
			last_facing_direction = Vector2(float(facing_array[0]), float(facing_array[1]))

			has_spoken_to_durmil = data.get("has_spoken_to_durmil", false)
			has_upgraded_pickaxe = data.get("has_upgraded_pickaxe", false)
		else:
			print("Error parsing saved data: ", json.get_error_message())
		file.close()
	else:
		print("No save file found, loading defaults.")


# Function for autosave (called every interval)
func _on_autosave_timeout():
	save_all_data()  # Save data
	print("Game autosaved.")

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
	save_all_data()


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

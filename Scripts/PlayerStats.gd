extends Node

@onready var global_state = get_node("/root/GlobalState")  # Sync player stats with GlobalState
@onready var inventory_panel = get_tree().get_first_node_in_group("inventory_panel")  # ✅ Uses group instead of fixed path
@onready var armor_panel = get_node("/root/TheCrossroads/MainUI/ArmorPanel")  # Reference to ArmorPanel
@onready var inventory = GlobalState.inventory  # ✅ Sync inventory reference
@onready var player = get_tree().get_first_node_in_group("player")


signal equipment_changed(slot_type, item_name)  # ✅ UI updates when equipment changes
@export var equipped_items := {
	"weapon": null,
	"helm": null,
	"chest": null,
	"legs": null,
	"shield": null,
	"pickaxe": null
}

# Player stats variables
var player_xp = 0          # Experience points
var health = 100           # Player health
var total_level = 1        # Total level (formerly player_level)

# Skill progression variables (Mining, Herbalism, Combat)
var mining_xp = 0
var herbalism_xp = 0
var combat_xp = 0

# Maximum levels for each skill
var max_skill_level = 20

# Skill levels (initial values; these will update based on XP)
var mining_level = 1
var herbalism_level = 1
var combat_level = 1

# Autosave Timer
var autosave_timer : Timer

# Equipment slots
var equipped_weapon = null  # Stores the equipped weapon (if any)
var equipped_armor = null   # Stores the equipped armor (if any)


# Called when the game starts
func _ready():
	print("🔄 [PlayerStats] Syncing with GlobalState on game start...")

	# ✅ Ensure inventory loads from GlobalState
	inventory = GlobalState.inventory
	print("📌 [PlayerStats] Loaded Inventory:", inventory)  # 🔹 Debugging Line
	update_ui()
	
	await get_tree().process_frame  # Ensures scene is fully loaded
	player = get_tree().get_first_node_in_group("player")
	print("🔄 Checking inventory format on game load...")

	# Ensure GlobalState.inventory is initialized
	if not GlobalState.inventory:
		GlobalState.inventory = {}

	# Ensure equipped items are loaded from GlobalState
	if "equipped_items" in GlobalState:
		equipped_items = GlobalState.equipped_items
	else:
		GlobalState.equipped_items = equipped_items  # Default values

	print("📌 Equipped Items Loaded:", equipped_items)
	
	# Ensure inventory is initialized
	if not GlobalState.inventory:
		GlobalState.inventory = {}

	# ✅ Convert old inventory format (single number) to dictionary format
	for item_name in GlobalState.inventory.keys():
		var item = GlobalState.inventory[item_name]

		# Convert single number to dictionary format
		if typeof(item) == TYPE_FLOAT or typeof(item) == TYPE_INT:
			print("⚠️ Fixing inventory format for:", item_name)
			GlobalState.inventory[item_name] = { "quantity": int(item), "type": "unknown" }

		# Ensure item type is properly assigned
		if typeof(item) == TYPE_DICTIONARY and (!item.has("type") or item["type"] == "unknown"):
			if GlobalState.item_types.has(item_name):
				GlobalState.inventory[item_name]["type"] = GlobalState.item_types[item_name]
				print("✅ Assigned correct type to:", item_name)

	# ✅ Ensure Hollowed Pickaxe format is correct
	if "Hollowed Pickaxe" in GlobalState.inventory:
		var pickaxe_data = GlobalState.inventory["Hollowed Pickaxe"]
		if typeof(pickaxe_data) != TYPE_DICTIONARY or !pickaxe_data.has("type"):
			print("⚠️ Fixing Hollowed Pickaxe format...")
			GlobalState.inventory["Hollowed Pickaxe"] = { "quantity": 0, "type": "pickaxe" }

	# ✅ Apply Fixed Inventory Locally
	inventory = GlobalState.inventory

	# Initialize stats from GlobalState (when loading the game)
	load_player_stats()
	# Update computed skill levels from XP values
	update_skill_levels()
	
	# Initialize autosave functionality
	autosave_timer = Timer.new()
	add_child(autosave_timer)
	autosave_timer.wait_time = 60  # Autosave interval set to 60 seconds
	autosave_timer.one_shot = false  # Repeat after each interval
	autosave_timer.connect("timeout", Callable(self, "_on_autosave_timeout"))
	autosave_timer.start()

# Function to load player stats (from GlobalState or file)
func load_player_stats():
	player_xp = GlobalState.player_xp
	total_level = GlobalState.total_level
	health = GlobalState.health
	mining_xp = GlobalState.mining_xp
	herbalism_xp = GlobalState.herbalism_xp
	combat_xp = GlobalState.combat_xp
	inventory = GlobalState.inventory  # Assuming inventory is in GlobalState

# Function to update computed skill levels based on current XP values.
func update_skill_levels():
	mining_level = min(int(mining_xp / 100) + 1, max_skill_level)
	herbalism_level = min(int(herbalism_xp / 100) + 1, max_skill_level)
	combat_level = min(int(combat_xp / 100) + 1, max_skill_level)
	total_level = get_total_level()

# Function to gain XP for a specific skill
func gain_xp(skill: String, amount: int):
	match skill:
		"mining":
			mining_xp += amount
			check_level_up("mining")
		"herbalism":
			herbalism_xp += amount
			check_level_up("herbalism")
		"combat":
			combat_xp += amount
			check_level_up("combat")
		_:
			print("❌ Error: Unknown skill for XP gain!")
	# After modifying XP, update the skill levels and sync stats
	update_skill_levels()
	sync_player_stats()

# Function to check if the skill has leveled up
func check_level_up(skill: String):
	var xp_needed = get_xp_for_next_level(skill)
	var current_xp = 0
	var current_level = 0

	match skill:
		"mining":
			current_xp = mining_xp
			current_level = get_skill_level("mining")
		"herbalism":
			current_xp = herbalism_xp
			current_level = get_skill_level("herbalism")
		"combat":
			current_xp = combat_xp
			current_level = get_skill_level("combat")

	if current_xp >= xp_needed and current_level < max_skill_level:
		current_level += 1
		print(skill + " leveled up to level " + str(current_level))
		# Optionally apply level-up rewards or bonuses here

	# Update skill levels after a potential level-up and sync stats
	update_skill_levels()
	sync_player_stats()

# Function to get XP needed for the next level for a given skill
func get_xp_for_next_level(skill: String) -> int:
	return 100 * (get_skill_level(skill) + 1)  # Basic XP formula; adjust as needed

# Function to get the current level for a specific skill (calculated from XP)
func get_skill_level(skill: String) -> int:
	match skill:
		"mining":
			return min(int(mining_xp / 100) + 1, max_skill_level)
		"herbalism":
			return min(int(herbalism_xp / 100) + 1, max_skill_level)
		"combat":
			return min(int(combat_xp / 100) + 1, max_skill_level)
	return 0

# Function to handle leveling up (general)
func level_up():
	# Example: If total XP exceeds a threshold, increase total level
	var xp_needed_for_level_up = 1000 * total_level  # Example: 1000 XP per level
	if player_xp >= xp_needed_for_level_up:
		total_level += 1
		player_xp = 0  # Reset XP on level up
		print("Level Up! New level: " + str(total_level))
		sync_player_stats()  # Sync updated stats with GlobalState

# Function to calculate the total level (sum of all skill levels, capped at 70)
func get_total_level() -> int:
	var total_skill_level = get_skill_level("mining") + get_skill_level("herbalism") + get_skill_level("combat")
	return min(total_skill_level, 70)  # Cap total level at 70

# Sync player stats with GlobalState (for persistence)
# Sync player stats with GlobalState (for persistence)
func sync_player_stats():
	# Calculate total level (sum of skill levels)
	total_level = get_total_level()

	GlobalState.player_xp = player_xp
	GlobalState.total_level = total_level
	GlobalState.health = health
	GlobalState.mining_xp = mining_xp
	GlobalState.herbalism_xp = herbalism_xp
	GlobalState.combat_xp = combat_xp
	
	# Syncs up inventory and equipped items (Armor, Pickaxe and Weapons)
	GlobalState.inventory = inventory  # Sync inventory
	GlobalState.equipped_items = equipped_items 

	GlobalState.save_all_data()  # ✅ Save everything

func sync_with_global_state():
	global_state.equipped_items = equipped_items
	global_state.inventory = inventory
	global_state.save_all_data()

	print("✅ Synced PlayerStats with GlobalState")

# Declare the signal in PlayerStats.gd
signal inventory_updated
func add_item_to_inventory(item_name: String, quantity: int):
	# Normalize item name by removing any potential suffix like "_ore" from the ore type
	var normalized_name = item_name.replace("_ore", "")  # Ensure consistent naming

	# Check if item is already in inventory
	if inventory.has(normalized_name):
		inventory[normalized_name]["quantity"] += quantity  # Increase quantity
	else:
		inventory[normalized_name] = {
			"quantity": quantity,
			"type": "ore"  # Set type as "ore"
		}

	  # Emit the signal to notify the UI to update
	emit_signal("inventory_updated")
	# Sync with GlobalState or save the updated inventory
	GlobalState.inventory = inventory
	GlobalState.save_all_data()

	print("📌 Updated Inventory:", inventory)

# ✅ Get item type from GlobalState
func get_item_type(item_name: String) -> String:
	if GlobalState.item_types.has(item_name):
		return GlobalState.item_types[item_name]
	return "unknown"  # Default if item type is missing

# PlayerStats.gd

# Sync inventory and equipped items with GlobalState
# PlayerStats.gd

# Sync inventory and equipped items with GlobalState
func sync_inventory_with_player():
	# Sync the inventory and equipped items with GlobalState
	GlobalState.inventory = inventory
	GlobalState.equipped_items = equipped_items

	# Save data to GlobalState
	GlobalState.save_all_data()

	# Update the UI
	if inventory_panel:
		inventory_panel.update_inventory_panel()  # Ensure inventory is up to date

	if armor_panel:
		armor_panel.load_equipped_items()  # Ensure armor panel is updated
	else:
		print("❌ ERROR: ArmorPanel not found!")

	print("🔄 Inventory and Equipped Items synced and UI updated.")

# Get the currently equipped item (for UI display, etc.)
func get_equipped_item(item_type: String) -> String:
	print("Getting equipped item for type:", item_type)  # Debugging the requested item type
	
	if item_type == "weapon":
		if equipped_weapon != null:
			print("Equipped weapon: ", equipped_weapon.name)  # Debugging the equipped weapon
			return equipped_weapon.name
		else:
			print("No weapon equipped.")  # Debugging when no weapon is equipped
			return "None"
	elif item_type == "armor":
		if equipped_armor != null:
			print("Equipped armor: ", equipped_armor.name)  # Debugging the equipped armor
			return equipped_armor.name
		else:
			print("No armor equipped.")  # Debugging when no armor is equipped
			return "None"
	
	print("Invalid item type:", item_type)  # Debugging invalid item types
	return "Invalid item type"


# Function for autosave (called every interval)
func _on_autosave_timeout():
	GlobalState.save_all_data()  # Save data

# Optionally, trigger manual save when a key is pressed (e.g., F5 or Ctrl+S)
func _process(delta):
	if Input.is_action_pressed("save_game"):  # Make sure to add this action in Input Map
		GlobalState.save_all_data()  # Save data manually
		print("Game saved manually.")

# ✅ EQUIP AN ITEM FROM INVENTORY
func equip_item(slot_type: String, item_name: String):
	print("✅ [PlayerStats] Attempting to equip:", item_name, "to", slot_type)

	# ✅ Ensure slot is available
	if equipped_items.get(slot_type):
		print("❌ [PlayerStats] ERROR: Slot", slot_type, "already occupied by", equipped_items[slot_type])
		return

	# ✅ Remove item from inventory before equipping
	if inventory.has(item_name):
		inventory.erase(item_name)
	else:
		print("❌ [PlayerStats] ERROR: Item", item_name, "not found in inventory!")
		return

	# ✅ Equip the item
	equipped_items[slot_type] = item_name
	sync_with_global_state()

	print("✅ [PlayerStats] Successfully equipped:", item_name, "to", slot_type)

	# ✅ Update UI & Pickaxe Visibility
	update_ui()
	update_pickaxe_visibility()

func unequip_item(slot_type: String):
	print("🛠 [PlayerStats] Called unequip_item() for:", slot_type)

	if not equipped_items.has(slot_type):
		print("❌ [PlayerStats] ERROR: Slot does not exist in equipped_items:", slot_type)
		return

	var item = equipped_items[slot_type]
	if item:
		print("❎ [PlayerStats] Unequipping:", item, "from", slot_type)

		# ✅ Ensure item is returned to inventory
		if inventory.has(item):
			inventory[item]["quantity"] += 1
		else:
			inventory[item] = {"quantity": 1, "type": GlobalState.get_item_type(item)}

		# ✅ Remove item from equipped slot
		equipped_items[slot_type] = ""

		# ✅ Save all data to GlobalState
		GlobalState.equipped_items = equipped_items
		GlobalState.inventory = inventory  # <- 🔹 Ensure inventory is saved here!
		GlobalState.save_all_data()

		print("✅ [PlayerStats] Successfully unequipped", item)
		print("📌 Updated GlobalState Inventory:", GlobalState.inventory)
	else:
		print("⚠️ [PlayerStats] WARNING: No item to unequip in slot", slot_type)


	# ✅ Update UI & Pickaxe Visibility
	update_ui()
	player.update_pickaxe_visibility()

# Function to return the correct slot type for an item
func get_slot_by_type(item_type: String) -> String:
	match item_type:
		"weapon", "pickaxe":  # Pickaxes are also considered weapons
			return "weapon"
		"helm":
			return "helm"
		"chest":
			return "chest"
		"legs":
			return "legs"
		"shield":
			return "shield"
	return ""

# Function to refresh the inventory UI
func update_ui():
	print("🔄 [PlayerStats] Updating UI after equip/unequip...")

	# ✅ Update Armor Panel
	var armor_panel = get_tree().get_first_node_in_group("armor_ui")
	if armor_panel:
		print("✅ [PlayerStats] Found Armor Panel. Reloading UI...")
		armor_panel.load_equipped_items()
	else:
		print("❌ [PlayerStats] ERROR: Armor Panel not found!")

	# ✅ Update Inventory Panel
	var inventory_panel = get_tree().get_first_node_in_group("inventory_ui")
	if inventory_panel:
		print("✅ [PlayerStats] Found Inventory Panel. Updating UI...")
		inventory_panel.call_deferred("update_inventory_ui")  # ✅ Correct Call
	else:
		print("❌ [PlayerStats] ERROR: Inventory Panel not found!")


func update_pickaxe_visibility():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.update_pickaxe_visibility()
	else:
		print("❌ [PlayerStats] ERROR: Player not found when updating pickaxe visibility!")

extends Node

@onready var inventory_panel = get_tree().get_first_node_in_group("inventory_panel")  # ✅ Uses group instead of fixed path
@onready var armor_panel = get_node("/root/TheCrossroads/MainUI/ArmorPanel")  # Reference to ArmorPanel

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

var inventory = {}  # Dictionary to hold inventory items with their name, type, and quantity

# Equipment slots
var equipped_weapon = null  # Stores the equipped weapon (if any)
var equipped_armor = null   # Stores the equipped armor (if any)
# Track Equipped Items
var equipped_items = {
	"weapon": null,
	"armor": null,
	"pickaxe": null  # ✅ Ensure "pickaxe" exists here
}

# Called when the game starts
func _ready():
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

# Function to add an item to the player's inventory
func add_item_to_inventory(item_name: String):
	if item_name in inventory:
		if typeof(inventory[item_name]) == TYPE_DICTIONARY:
			inventory[item_name]["quantity"] += 1
		else:
			print("⚠️ Converting old inventory format for:", item_name)
			inventory[item_name] = {
				"quantity": 1,
				"type": get_item_type(item_name)  # ✅ Fetch correct type
			}
	else:
		inventory[item_name] = {
			"quantity": 1,
			"type": get_item_type(item_name)  # ✅ Ensure type is set
		}

	# ✅ Sync with GlobalState
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
	if item_type == "weapon":
		return equipped_weapon.name if equipped_weapon != null else "None"
	elif item_type == "armor":
		return equipped_armor.name if equipped_armor != null else "None"
	return "Invalid item type"

# Function for autosave (called every interval)
func _on_autosave_timeout():
	GlobalState.save_all_data()  # Save data

# Optionally, trigger manual save when a key is pressed (e.g., F5 or Ctrl+S)
func _process(delta):
	if Input.is_action_pressed("save_game"):  # Make sure to add this action in Input Map
		GlobalState.save_all_data()  # Save data manually
		print("Game saved manually.")

# Equip an item from the inventory to the specified slot
func equip_item(item_name: String):
	if not inventory.has(item_name):
		print("❌ ERROR: Item not found in inventory:", item_name)
		return

	var item_type = GlobalState.get_item_type(item_name)
	var slot_type = get_slot_for_item_type(item_type)

	if not slot_type:
		print("❌ ERROR: No valid slot for", item_name)
		return

	print("📌 Equipping", item_name, "to", slot_type)

	# ✅ Ensure slot is empty before equipping
	if equipped_items.has(slot_type) and equipped_items[slot_type] != "":
		print("❌ ERROR: Slot", slot_type, "is already occupied by", equipped_items[slot_type])
		return

	# ✅ Equip the item
	equipped_items[slot_type] = item_name
	GlobalState.equipped_items[slot_type] = item_name
	GlobalState.inventory.erase(item_name)  # ✅ Remove from inventory
	GlobalState.save_all_data()

	# ✅ Update UI
	print("🔄 Updating Armor & Inventory UI after equip")
	var armor_panel = get_tree().get_first_node_in_group("armor_ui")
	if armor_panel:
		print("✅ ArmorPanel found, updating equipped items")
		armor_panel.load_equipped_items()
	else:
		print("❌ ERROR: ArmorPanel UI not found!")

	if inventory_panel == null:
		inventory_panel = get_tree().get_root().find_child("InventoryPanel", true, false)


	print("✅ Finished equipping:", item_name)



func unequip_item(item_name: String):
	var slot_type = ""
	for slot in equipped_items.keys():
		if equipped_items[slot] == item_name:
			slot_type = slot
			break

	if slot_type == "":
		print("❌ ERROR: Item", item_name, "not found in equipped items")
		return

	# ✅ Return item to inventory
	if inventory.has(item_name):
		inventory[item_name]["quantity"] += 1
	else:
		inventory[item_name] = {"quantity": 1, "type": GlobalState.get_item_type(item_name)}

	# ✅ Remove from equipped items
	equipped_items[slot_type] = ""
	GlobalState.equipped_items[slot_type] = ""
	GlobalState.save_all_data()

	# ✅ Update UI
	var armor_panel = get_tree().get_first_node_in_group("armor_ui")
	if armor_panel:
		armor_panel.load_equipped_items()

	var inventory_panel = get_tree().get_first_node_in_group("inventory_ui")
	if inventory_panel:
		inventory_panel.update_inventory_ui()

	print("❎ Unequipped", item_name, "from", slot_type)




# Function to return the correct slot type for an item
func get_slot_for_item_type(item_type: String) -> String:
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
func update_inventory_ui():
	if inventory_panel == null:
		inventory_panel = get_tree().get_root().find_child("InventoryPanel", true, false)


# Function to update the visibility of the pickaxe in the player's hand
func update_pickaxe_visibility():
	# Get the currently equipped weapon (e.g., pickaxe)
	var equipped_weapon = GlobalState.equipped_items.get("weapon", null)

	# Check if the equipped weapon is a pickaxe
	if equipped_weapon and GlobalState.get_item_type(equipped_weapon) == "pickaxe":
		# Show pickaxe sprite and set its texture
		var pickaxe_sprite = get_node_or_null("PickaxeSprite")
		if pickaxe_sprite:
			pickaxe_sprite.visible = true
			pickaxe_sprite.texture = load("res://assets/items/" + equipped_weapon + ".png")
	else:
		# Hide the pickaxe sprite if not equipped
		var pickaxe_sprite = get_node_or_null("PickaxeSprite")
		if pickaxe_sprite:
			pickaxe_sprite.visible = false
			pickaxe_sprite.texture = null

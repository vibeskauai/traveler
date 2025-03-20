extends Panel

@onready var global_state = get_node("/root/GlobalState")  # Access GlobalState for syncing inventory data
@onready var player_stats = get_node("/root/PlayerStats")  # Reference to PlayerStats node
@onready var inventory_grid = $InventoryPanel/GridContainer  # Access the inventory grid to populate with items
@onready var armor_panel = get_node("/root/TheCrossroads/MainUI/ArmorPanel")  # Reference to ArmorPanel


const TOTAL_SLOTS = 28  # Max inventory slots
var equipped_item: String = ""  # Track equipped item (if any)

@onready var inventory_panel: Control = null  # Declare it for global use

# Initialize the UI when the scene is ready
func _ready():
	print("🔄 [Inventory] Updating UI after game load...")
	player_stats.connect("inventory_updated", Callable(self, "_on_inventory_updated"))
	# ✅ Sync inventory with GlobalState
	player_stats.inventory = GlobalState.inventory

	# Initialize inventory panel and check its validity
	inventory_panel = get_tree().get_root().find_child("InventoryPanel", true, false)
	
	if inventory_panel:
		print("✅ InventoryPanel found dynamically!")
		update_inventory_ui()  # Call function to refresh UI after the panel is found
	else:
		print("❌ ERROR: InventoryPanel not found! Check scene structure.")
	
	# Check if GridContainer exists inside InventoryPanel
	if inventory_panel and inventory_panel.has_node("GridContainer"):
		inventory_grid = inventory_panel.get_node("GridContainer")
		print("✅ GridContainer loaded successfully!")
	else:
		print("❌ ERROR: GridContainer not found in InventoryPanel!")

# Function to update the inventory UI when inventory changes
func _on_inventory_updated():
	update_inventory_ui()  # Call this to refresh the UI whenever the inventory changes
	
# Refresh the inventory UI when equipping or adding/removing items
func update_inventory_ui():
	print("🔄 Updating Inventory UI...")
	# Debug: Print the current inventory in PlayerStats
	var player_stats = get_node("/root/PlayerStats")
	if player_stats:
		print("📌 Current Inventory:", player_stats.inventory)
	else:
		print("❌ PlayerStats not found!")
	
	# Check if inventory grid exists
	if not inventory_grid:
		print("❌ ERROR: Inventory grid not found!")
		return
	
	# ✅ Remove old buttons before refreshing the UI
	for child in inventory_grid.get_children():
		child.queue_free()

	# ✅ Re-add inventory items
	var inventory = player_stats.inventory  # Get inventory from PlayerStats
	for item_name in inventory.keys():
		print("📌 Adding item button for:", item_name)  # Debugging line to check the item
		add_item_button(item_name)  # Add button for each item
	
	print("✅ Inventory UI updated.")

# Function to add an item button with icon and quantity to the inventory UI
# Add item button to inventory and display quantity if not pickaxe/weapon/armor
func add_item_button(item_name: String):
	if not inventory_grid:
		print("❌ ERROR: Inventory grid not found!")
		return

	# Create item button for inventory slot
	var item_button = Button.new()
	item_button.text = ""  # Icon-only button
	item_button.custom_minimum_size = Vector2(52, 52)  # Set button size
	item_button.flat = true
	item_button.focus_mode = Control.FOCUS_NONE
	item_button.name = item_name  # Assign the item_name as the button's name
	item_button.connect("pressed", Callable(self, "_on_item_button_pressed").bind(item_name))

	# Create and configure item icon
	var icon_rect = TextureRect.new()
	icon_rect.stretch_mode = TextureRect.STRETCH_SCALE
	icon_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon_rect.offset_left = -5
	icon_rect.offset_top = -5
	icon_rect.offset_right = -10
	icon_rect.offset_bottom = -10

	# Load texture for the item icon
	var item_path = "res://assets/items/" + item_name + ".png"
	if FileAccess.file_exists(item_path):
		icon_rect.texture = load(item_path)
	else:
		icon_rect.texture = load("res://assets/ui/default_item.png")  # Default item icon

	# Add the icon to the button
	item_button.add_child(icon_rect)

	# **Skip adding the count label for items of type 'pickaxe', 'weapon', or 'armor'**
	var item_type = global_state.get_item_type(item_name)  # Get item type
	if item_type != "pickaxe" and item_type != "weapon" and item_type != "armor":
		# Create label for displaying quantity
		var count_label = Label.new()
		count_label.text = str(int(player_stats.inventory[item_name]["quantity"]))  # No decimals
		count_label.add_theme_font_size_override("font_size", 14)  # Set font size
		count_label.add_theme_color_override("font_color", Color(1, 1, 1))  # White text
		count_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))  # Black outline

		# Create a container to manually position the label
		var label_container = Control.new()
		label_container.add_child(count_label)

		# Position count label inside the top-left of the item icon
		label_container.anchor_left = 0.0
		label_container.anchor_top = 0.0
		label_container.anchor_right = 0.0
		label_container.anchor_bottom = 0.0

		# Position label inside the container
		count_label.position = Vector2(-5, -5)  # Fine-tuned for top-left corner
		count_label.z_index = 2  # Ensure label is on top of the icon

		# Attach the label container to the item icon
		item_button.add_child(label_container)

	# Add the button to the inventory grid
	inventory_grid.add_child(item_button)
	print("📌 Added item button for:", item_name)


# Handle item button presses (equip/unequip items)
func _on_item_button_pressed(item_name: String):
	print("🖱️ [DEBUG] Item button pressed:", item_name)

	if not player_stats:
		print("❌ ERROR: PlayerStats not found!")
		return

	if not player_stats.inventory.has(item_name):
		print("❌ ERROR: Item not found in inventory:", item_name)
		return

	# If already equipped, unequip it
	if item_name in player_stats.equipped_items.values():
		print("🔄 Unequipping:", item_name)
		player_stats.unequip_item(item_name)
	else:
		print("✅ Equipping:", item_name)
		var item_type = global_state.get_item_type(item_name)
		var slot_type = get_slot_for_item_type(item_type)

		if slot_type:
			print("📌 Assigning", item_name, "to", slot_type)
			player_stats.equip_item(slot_type, item_name)
		else:
			print("❌ ERROR: No valid slot for", item_name)

	update_inventory_ui()  # Update the inventory UI
	GlobalState.save_all_data()  # Save all data

# Determine which slot an item should go into based on its type
func get_slot_for_item_type(item_type: String) -> String:
	match item_type:
		"weapon", "pickaxe":
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

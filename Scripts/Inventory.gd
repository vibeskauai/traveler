extends Panel

@onready var global_state = get_node("/root/GlobalState")  # Access GlobalState for syncing inventory data
@onready var player_stats = get_node("/root/PlayerStats")  # Reference to PlayerStats node
@onready var inventory_grid = $InventoryPanel/GridContainer
@onready var armor_panel = get_node("/root/TheCrossroads/MainUI/ArmorPanel")  # Reference to ArmorPanel


const TOTAL_SLOTS = 28  # Max inventory slots
var equipped_item: String = ""  # Track equipped item (if any)

@onready var inventory_panel: Control = null  # Declare it for global use

func _ready():
	print("🔄 [Inventory] Updating UI after game load...")
	mouse_filter = Control.MOUSE_FILTER_STOP  # Blocks clicks from reaching the game world
	# ✅ Force inventory to sync with GlobalState
	player_stats.inventory = GlobalState.inventory

	update_inventory_ui()
	print("🔍 Checking Inventory Panel...")

	inventory_panel = get_tree().get_root().find_child("InventoryPanel", true, false)

	if inventory_panel:
		print("✅ InventoryPanel found dynamically!")
	else:
		print("❌ ERROR: InventoryPanel not found! Check scene structure.")

	if inventory_panel and inventory_panel.has_node("GridContainer"):
		inventory_grid = inventory_panel.get_node("GridContainer")
		print("✅ GridContainer loaded successfully!")
	else:
		print("❌ ERROR: GridContainer not found in InventoryPanel!")


# Refresh the inventory UI properly when equipping items
func update_inventory_ui():
	print("🔄 Updating Inventory UI...")
	
	# Debug inventory contents
	print("📌 Current Inventory:", player_stats.inventory)

	update_inventory()  # Call function to refresh UIresh UI

	if not inventory_grid:
		print("❌ ERROR: Inventory grid not found!")
		return

	# ✅ Remove old buttons
	for child in inventory_grid.get_children():
		child.queue_free()

	# ✅ Re-add inventory items
	for item_name in GlobalState.inventory.keys():
		add_item_button(item_name)

	update_inventory()

	# Force Armor Panel update when equipping/unequipping
	var armor_panel = get_tree().get_root().get_node("MainUI/ArmorPanel")
	if armor_panel:
		armor_panel.load_equipped_items()  # This will update the equipped items UI

	# Refresh the UI to reflect updated inventory and equipped items
	if inventory_panel == null:
		inventory_panel = get_tree().get_root().find_child("InventoryPanel", true, false)

# ✅ **Update the inventory UI with exactly 28 slots**
func update_inventory():
	if not inventory_grid:
		print("❌ ERROR: Inventory grid not found!")
		return

	# Remove all existing item buttons before refreshing
	for child in inventory_grid.get_children():
		child.queue_free()

	# Loop through the player's inventory and display items
	for item_name in player_stats.inventory.keys():
		var item_data = player_stats.inventory[item_name]
		
		# ✅ **Skip adding items with 0 or negative quantity**
		if typeof(item_data) == TYPE_DICTIONARY and item_data.has("quantity") and item_data["quantity"] <= 0:
			print("🗑️ Removing empty inventory slot for:", item_name)
			continue  # Skip adding this item to UI

		# ✅ Create item button for inventory slot
		var item_button = Button.new()
		item_button.text = ""  # icon-only button
		item_button.custom_minimum_size = Vector2(64, 64)
		item_button.flat = true
		item_button.focus_mode = Control.FOCUS_NONE
		item_button.name = item_name  # Assign the item_name as the button's name

		# ✅ Ensure the button press is connected
		if not item_button.is_connected("pressed", Callable(self, "_on_item_button_pressed").bind(item_name)):
			item_button.connect("pressed", Callable(self, "_on_item_button_pressed").bind(item_name))
			print("✅ Connected button for:", item_name)
		else:
			print("⚠️ Button already connected for:", item_name)

		# ✅ Create and configure item icon
		var icon_rect = TextureRect.new()
		icon_rect.stretch_mode = TextureRect.STRETCH_SCALE
		icon_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon_rect.offset_left = -5
		icon_rect.offset_top = -5
		icon_rect.offset_right = -10
		icon_rect.offset_bottom = -10

		# ✅ Load texture for the item icon
		var item_path = "res://assets/items/" + item_name + ".png"
		if FileAccess.file_exists(item_path):
			icon_rect.texture = load(item_path)
		else:
			icon_rect.texture = load("res://assets/ui/default_item.png")  # Default item icon
		
		# ✅ Add the icon to the button, then add button to inventory grid
		item_button.add_child(icon_rect)
		inventory_grid.add_child(item_button)
		print("📌 Added item button for:", item_name)


func add_item_to_inventory(item_name: String):
	if not inventory_grid:
		print("❌ ERROR: Inventory grid not found!")
		return

	# ✅ Add item to inventory dictionary (if it doesn't already exist)
	if not GlobalState.inventory.has(item_name):
		GlobalState.inventory[item_name] = {"quantity": 1, "type": "pickaxe"}
	else:
		GlobalState.inventory[item_name]["quantity"] += 1  # Increase quantity

	# ✅ Call the function to visually add the item button
	add_item_button(item_name)

	print("📌 Item added back to inventory:", item_name)


func add_item_button(item_name: String):
	if not inventory_grid:
		print("❌ ERROR: Inventory grid not found!")
		return

	# ✅ Create item button for inventory slot
	var item_button = Button.new()
	item_button.text = ""  # Icon-only button
	item_button.custom_minimum_size = Vector2(52, 52)
	item_button.flat = true
	item_button.focus_mode = Control.FOCUS_NONE
	item_button.name = item_name  # Assign the item_name as the button's name
	item_button.connect("pressed", Callable(self, "_on_item_button_pressed").bind(item_name))

	# ✅ Create and configure item icon
	var icon_rect = TextureRect.new()
	icon_rect.stretch_mode = TextureRect.STRETCH_SCALE
	icon_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon_rect.offset_left = -5
	icon_rect.offset_top = -5
	icon_rect.offset_right = -10
	icon_rect.offset_bottom = -10

	# ✅ Load texture for the item icon
	var item_path = "res://assets/items/" + item_name + ".png"
	if FileAccess.file_exists(item_path):
		icon_rect.texture = load(item_path)
	else:
		icon_rect.texture = load("res://assets/ui/default_item.png")  # Default item icon

	# ✅ Add the icon to the button, then add button to inventory grid
	item_button.add_child(icon_rect)
	inventory_grid.add_child(item_button)

	print("📌 Added item button for:", item_name)



# Update UI when item is equipped or unequipped
func update_inventory_item(item_id: String) -> void:
	var item_button = inventory_grid.find_child(item_id, true, false)  
	if item_button:
		var item_icon = item_button.get_child(0)  

		# Remove equipped items from inventory display
		if player_stats.equipped_items.has("weapon") and player_stats.equipped_items["weapon"] == item_id:
			print("🎯 Removing weapon from inventory:", item_id)
			item_button.queue_free()

		elif player_stats.equipped_items.has("helm") and player_stats.equipped_items["helm"] == item_id:
			print("🎯 Removing helm from inventory:", item_id)
			item_button.queue_free()

		elif player_stats.equipped_items.has("chest") and player_stats.equipped_items["chest"] == item_id:
			print("🎯 Removing chest from inventory:", item_id)
			item_button.queue_free()

		elif player_stats.equipped_items.has("legs") and player_stats.equipped_items["legs"] == item_id:
			print("🎯 Removing legs from inventory:", item_id)
			item_button.queue_free()

		elif player_stats.equipped_items.has("shield") and player_stats.equipped_items["shield"] == item_id:
			print("🎯 Removing shield from inventory:", item_id)
			item_button.queue_free()

		elif player_stats.equipped_items.has("pickaxe") and player_stats.equipped_items["pickaxe"] == item_id:
			print("🎯 Removing pickaxe from inventory:", item_id)
			item_button.queue_free()

		else:
			print("📌 Setting icon for item:", item_id)
			item_icon.texture = get_item_icon(item_id)  # Update the item icon
	else:
		print("❌ ERROR: Inventory slot not found for:", item_id)


# ✅ **Retrieve the icon for a specific item**
func get_item_icon(item_name: String) -> Texture:
	var item_path = "res://assets/items/" + item_name + ".png"

	if FileAccess.file_exists(item_path):
		print("✅ Icon found for:", item_name, "at path:", item_path)
		return load(item_path)
	else:
		print("⚠️ Missing icon for:", item_name, "expected path:", item_path)
		return load("res://assets/ui/default_item.png")  # Use default icon if missing


func _on_item_button_pressed(item_name: String):
	print("🖱️ [DEBUG] Item button pressed:", item_name)

	if not player_stats:
		print("❌ ERROR: PlayerStats not found!")
		return

	if not player_stats.inventory.has(item_name):
		print("❌ ERROR: Item not found in inventory:", item_name)
		return

	# ✅ If already equipped, unequip it
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

	update_inventory_ui()
	GlobalState.save_all_data()

# ✅ Determines which slot an item should go into
func get_slot_for_item_type(item_type: String) -> String:
	match item_type:
		"weapon", "pickaxe":  # ✅ Pickaxes now count as weapons
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

extends Panel

@onready var player_stats = get_node("/root/PlayerStats")  # Reference to PlayerStats node
@onready var inventory_grid = $InventoryPanel/GridContainer
@onready var armor_panel = get_node("/root/TheCrossroads/MainUI/ArmorPanel")  # Reference to ArmorPanel


const TOTAL_SLOTS = 28  # Max inventory slots
var equipped_item: String = ""  # Track equipped item (if any)

@onready var inventory_panel: Control = null  # Declare it for global use

func _ready():
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
	update_inventory()

	# Force Armor Panel update when equipping/unequipping
	var armor_panel = get_tree().get_root().get_node("MainUI/ArmorPanel")
	if armor_panel:
		armor_panel.load_equipped_items()  # This will update the equipped items UI

	# Refresh the UI to reflect updated inventory and equipped items
	if inventory_panel == null:
		inventory_panel = get_tree().get_root().find_child("InventoryPanel", true, false)

func update_inventory_panel():
	print("🔄 Updating Inventory UI...")
	update_inventory()  # ✅ Call the function that refreshes UI


# ✅ **Update the inventory UI with exactly 28 slots**
func update_inventory():
	print("🔄 Updating Inventory UI...")

	# Make sure the inventory panel is valid
	if not inventory_grid:
		print("❌ ERROR: Inventory grid not found!")
		return

	# Remove all existing item buttons before refreshing
	for child in inventory_grid.get_children():
		child.queue_free()

	# Loop through the player's inventory and display items
	for item_name in GlobalState.inventory.keys():
		var item_data = GlobalState.inventory[item_name]

		# Skip empty inventory slots
		if typeof(item_data) == TYPE_DICTIONARY and item_data.has("quantity") and item_data["quantity"] <= 0:
			continue

		# Create inventory button
		var item_button = Button.new()
		item_button.text = ""
		item_button.custom_minimum_size = Vector2(64, 64)
		item_button.flat = true
		item_button.name = item_name
		item_button.connect("pressed", Callable(self, "_on_item_button_pressed").bind(item_name))

		# Load item icon
		var icon_rect = TextureRect.new()
		icon_rect.stretch_mode = TextureRect.STRETCH_SCALE
		icon_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

		var item_path = "res://assets/items/" + item_name + ".png"
		if FileAccess.file_exists(item_path):
			icon_rect.texture = load(item_path)
		else:
			icon_rect.texture = load("res://assets/ui/default_item.png")

		# Add icon to button & button to inventory grid
		item_button.add_child(icon_rect)
		inventory_grid.add_child(item_button)

		print("📌 Added item button for:", item_name)


# ✅ **Updates inventory when an item is equipped or unequipped**
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
func get_item_icon(item_id: String) -> Texture:
	var item_path = "res://Assets/items/" + item_id + ".png"
	if FileAccess.file_exists(item_path):
		return load(item_path)
	return load("res://assets/ui/default_item.png")  # Default icon if missing

func _on_item_button_pressed(item_name: String):
	print("🖱️ [DEBUG] Item button pressed:", item_name)

	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("equip_item_from_inventory"):
		print("✅ Calling equip_item_from_inventory() for:", item_name)
		var item_type = GlobalState.get_item_type(item_name)
		var slot_type = get_slot_for_item_type(item_type)

		if slot_type:
			player.equip_item_from_inventory(item_name)
		else:
			print("❌ ERROR: No valid slot for", item_name)
	else:
		print("❌ ERROR: equip_item_from_inventory() function not found in Player!")



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

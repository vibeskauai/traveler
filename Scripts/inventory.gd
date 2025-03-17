extends Panel

@onready var player_stats = get_node("/root/PlayerStats")  # Reference to PlayerStats node
@onready var inventory_panel = get_node("/root/TheCrossroads/MainUI/InventoryPanel")  # Reference to InventoryPanel
@onready var inventory_grid = inventory_panel.get_node("GridContainer")  # Reference to GridContainer (fixed node path)

const TOTAL_SLOTS = 28

var equipped_item: String = ""  # Track equipped item (if any)

func _ready():
	update_inventory()
	# Update inventory UI based on player stats
	for item_name in player_stats.inventory.keys():
		update_inventory_item(item_name)

# ✅ **Global inventory UI update function**
func update_inventory_ui():
	print("🔄 Updating Inventory UI...")
	update_inventory()  # Ensures the UI refreshes properly

# ✅ **Update the inventory UI with exactly 28 slots**
func update_inventory():
	if not inventory_grid:
		print("❌ ERROR: Inventory grid not found!")
		return

	# Clear existing buttons
	for child in inventory_grid.get_children():
		child.queue_free()

	# Create new inventory slots for the items
	for item_name in player_stats.inventory.keys():
		var item_data = player_stats.inventory[item_name]
		
		# ✅ **Skip adding items with 0 or negative quantity**
		if typeof(item_data) == TYPE_DICTIONARY and item_data.has("quantity") and item_data["quantity"] <= 0:
			print("🗑️ Removing empty inventory slot for:", item_name)
			continue  # Skip adding this item to UI

		var item_button = Button.new()
		item_button.text = ""  # icon-only button
		item_button.custom_minimum_size = Vector2(64, 64)
		item_button.flat = true
		item_button.focus_mode = Control.FOCUS_NONE
		item_button.name = item_name  # Assign the item_name as the button's name
		item_button.connect("pressed", Callable(self, "_on_item_button_pressed").bind(item_name))

		# Create a TextureRect for the icon
		var icon_rect = TextureRect.new()
		icon_rect.stretch_mode = TextureRect.STRETCH_SCALE

		# Set anchors to fill the parent using the preset
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
			icon_rect.texture = load("res://assets/ui/default_item.png")
		
		# Add the TextureRect to the Button and the Button to the inventory grid
		item_button.add_child(icon_rect)
		inventory_grid.add_child(item_button)


# ✅ **Fix: Ensures item icon updates correctly when equipped/unequipped**
func update_inventory_item(item_id: String) -> void:
	var item_button = inventory_grid.find_child(item_id, true, false)  
	if item_button:
		var item_icon = item_button.get_child(0)  


		if player_stats.equipped_items.has("weapon") and player_stats.equipped_items["weapon"] == item_id:
			print("🎯 Removing weapon from inventory:", item_id)
			item_button.queue_free()  # ✅ Remove button from inventory UI

		elif player_stats.equipped_items.has("armor") and player_stats.equipped_items["armor"] == item_id:
			print("🎯 Removing armor from inventory:", item_id)
			item_button.queue_free()  # ✅ Remove button from inventory UI

		elif player_stats.equipped_items.has("pickaxe") and player_stats.equipped_items["pickaxe"] == item_id:
			print("🎯 Removing pickaxe from inventory:", item_id)
			item_button.queue_free()  # ✅ Properly remove pickaxe from inventory UI

		else:
			print("📌 Setting icon for item:", item_id)
			item_icon.texture = get_item_icon(item_id)  
	else:
		print("❌ ERROR: Inventory slot not found for:", item_id)


# ✅ **Retrieve the icon for a specific item**
func get_item_icon(item_id: String) -> Texture:
	match item_id:
		"Hollowed Pickaxe":
			return preload("res://Assets/items/Hollowed Pickaxe.png")  # Replace with your actual icon path
		# Add more items and their icons as needed
		_:
			return null  # Return null if the item doesn't exist

# ✅ **Handle the item button press event**
func _on_item_button_pressed(item_name: String):
	print("🖱️ [DEBUG] Item button pressed:", item_name)

	if not player_stats:
		print("❌ ERROR: PlayerStats not found!")
		return

	if not player_stats.inventory.has(item_name):
		print("❌ ERROR: Item not found in inventory:", item_name)
		return

	if item_name in player_stats.equipped_items.values():
		print("🔄 Unequipping:", item_name)
		if player_stats.has_method("unequip_item"):
			player_stats.unequip_item(item_name)
		else:
			print("❌ ERROR: unequip_item() function not found in PlayerStats!")
	else:
		print("✅ Equipping:", item_name)
		if player_stats.has_method("equip_item"):
			player_stats.equip_item(item_name)
		else:
			print("❌ ERROR: equip_item() function not found in PlayerStats!")

	update_inventory_ui()

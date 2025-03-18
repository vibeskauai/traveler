extends Panel

@onready var player_stats = get_node("/root/PlayerStats")  # Reference to PlayerStats node
@onready var inventory_panel = get_node("/root/TheCrossroads/MainUI/InventoryPanel")  # Reference to InventoryPanel
@onready var inventory_grid = inventory_panel.get_node("GridContainer")  # Reference to GridContainer (fixed node path)

const TOTAL_SLOTS = 28  # Max inventory slots
var equipped_item: String = ""  # Track equipped item (if any)

func _ready():
	update_inventory()
	# Populate inventory based on player stats
	for item_name in player_stats.inventory.keys():
		update_inventory_item(item_name)

# ✅ **Refreshes the inventory UI**
# ✅ Refresh inventory UI properly when equipping items
func update_inventory_ui():
	print("🔄 Updating Inventory UI...")
	update_inventory()
	
	# ✅ Force Armor Panel update when equipping/unequipping
	var armor_panel = get_tree().get_root().get_node("MainUI/ArmorPanel")
	if armor_panel:
		armor_panel.load_equipped_items()

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

# ✅ **Updates inventory when an item is equipped or unequipped**
func update_inventory_item(item_id: String) -> void:
	var item_button = inventory_grid.find_child(item_id, true, false)  
	if item_button:
		var item_icon = item_button.get_child(0)  

		# ✅ Remove equipped items from inventory display
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
			item_icon.texture = get_item_icon(item_id)  
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

	if not player_stats:
		print("❌ ERROR: PlayerStats not found!")
		return

	if not player_stats.inventory.has(item_name):
		print("❌ ERROR: Item not found in inventory:", item_name)
		return

	# ✅ **Check if the item is already equipped**
	if item_name in GlobalState.equipped_items.values():
		print("🔄 Unequipping:", item_name)
		if player_stats.has_method("unequip_item"):
			player_stats.unequip_item(item_name)
		else:
			print("❌ ERROR: unequip_item() function not found in PlayerStats!")

	# ✅ **Equip item into correct slot**
	else:
		print("✅ Equipping:", item_name)
		if player_stats.has_method("equip_item"):
			var item_type = GlobalState.get_item_type(item_name)
			var slot_type = get_slot_for_item_type(item_type)

			if slot_type:
				print("📌 Assigning", item_name, "to", slot_type)

				# ✅ **Sync with GlobalState & Update Player**
				GlobalState.equipped_items[slot_type] = item_name
				GlobalState.inventory.erase(item_name)  # ✅ Remove from inventory
				GlobalState.save_all_data()

				# ✅ **Make sure the UI updates**
				var armor_panel = get_tree().get_root().get_node("MainUI/ArmorPanel")
				if armor_panel:
					armor_panel.equip_item_from_inventory(slot_type, item_name)

				# ✅ **Force Player to Update Pickaxe Visibility**
				var player = get_tree().get_first_node_in_group("player")
				if player:
					player.update_pickaxe_visibility()
			else:
				print("❌ ERROR: No valid slot for", item_name)
		else:
			print("❌ ERROR: equip_item() function not found in PlayerStats!")

	# ✅ **Ensure UI Refreshes**
	update_inventory_ui()


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

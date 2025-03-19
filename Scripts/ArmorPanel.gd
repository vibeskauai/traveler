extends Control

@onready var helm_slot = $VBoxContainer/HelmSlot
@onready var chest_slot = $VBoxContainer/ChestRow/ChestSlot
@onready var weapon_slot = $VBoxContainer/ChestRow/WeaponSlot
@onready var shield_slot = $VBoxContainer/ChestRow/ShieldSlot
@onready var legs_slot = $VBoxContainer/LegsSlot
@onready var inventory_panel = get_tree().get_first_node_in_group("inventory_panel")


var equipped_items = {
	"weapon": null,
	"helm": null,
	"chest": null,
	"legs": null,
	"shield": null
}

func _ready():
	load_equipped_items()
	connect_slots()

# ✅ **Load equipped items from GlobalState & update UI**
# Load equipped items from GlobalState & update UI
func load_equipped_items():
	# Ensure equipped_items is always a valid dictionary
	equipped_items = GlobalState.equipped_items if GlobalState.equipped_items else {}

	# Default values to prevent `null` issues
	var default_slots = {
		"weapon": "",
		"helm": "",
		"chest": "",
		"legs": "",
		"shield": "",
		"pickaxe": ""  # Pickaxe is included in case it's needed
	}

	# Replace null values with empty strings
	for slot in default_slots.keys():
		if not equipped_items.has(slot) or equipped_items[slot] == null:
			equipped_items[slot] = default_slots[slot]

	# Update UI slots safely (prevents errors)
	update_slot(weapon_slot, equipped_items["weapon"])
	update_slot(helm_slot, equipped_items["helm"])
	update_slot(chest_slot, equipped_items["chest"])
	update_slot(legs_slot, equipped_items["legs"])
	update_slot(shield_slot, equipped_items["shield"])

	print("📂 Loaded Equipped Items in Armor Panel:", equipped_items)


# ✅ **Connect slot buttons to click event**
func connect_slots():
	if helm_slot:
		helm_slot.connect("pressed", Callable(self, "_on_slot_clicked").bind("helm"))
	else:
		print("❌ ERROR: helm_slot is NULL")

	if chest_slot:
		chest_slot.connect("pressed", Callable(self, "_on_slot_clicked").bind("chest"))
	else:
		print("❌ ERROR: chest_slot is NULL")

	if weapon_slot:
		weapon_slot.connect("pressed", Callable(self, "_on_slot_clicked").bind("weapon"))
	else:
		print("❌ ERROR: weapon_slot is NULL")

	if shield_slot:
		shield_slot.connect("pressed", Callable(self, "_on_slot_clicked").bind("shield"))
	else:
		print("❌ ERROR: shield_slot is NULL")

	if legs_slot:
		legs_slot.connect("pressed", Callable(self, "_on_slot_clicked").bind("legs"))
	else:
		print("❌ ERROR: legs_slot is NULL")


# ✅ **Handles clicking on equipment slots**
func _on_slot_clicked(slot_type: String):
	if equipped_items[slot_type]:  
		unequip_item(slot_type)  # ✅ Unequip properly
	else:
		var item_name = get_item_from_inventory(slot_type)
		if item_name:
			equip_item_from_inventory(slot_type, item_name)
		else:
			print("❌ ERROR: No item found in inventory for slot", slot_type)

	# ✅ Double-check slot was actually unequipped
	if not equipped_items[slot_type]:
		print("✅ Slot", slot_type, "is now empty.")  
	else:
		print("⚠️ Warning: Slot", slot_type, "still has:", equipped_items[slot_type])


# ✅ **Unequip an item and return it to the inventory**
# Unequip an item and return it to the inventory
func unequip_item(slot_type: String):
	var item = equipped_items.get(slot_type, null)
	if item:
		print("❎ Unequipping:", item, "from", slot_type)

		# Add the item back to the inventory
		if GlobalState.inventory.has(item):
			GlobalState.inventory[item]["quantity"] += 1
		else:
			GlobalState.inventory[item] = {"quantity": 1, "type": GlobalState.get_item_type(item)}

		# Remove item from equipped slot
		equipped_items[slot_type] = null
		GlobalState.equipped_items[slot_type] = null
		GlobalState.save_all_data()

		# Update UI
		var slot = get_slot_by_type(slot_type)
		if slot:
			update_slot(slot, "")

		# **Ensure Inventory UI Updates**
		var inventory_panel = get_inventory_panel()
		if inventory_panel:
			print("✅ InventoryPanel found, updating UI...")
			inventory_panel.update_inventory()
		else:
			print("❌ ERROR: InventoryPanel not found during unequip!")

func get_inventory_panel():
	var ui_root = get_tree().get_root().find_child("MainUI", true, false)
	if ui_root:
		var inventory = ui_root.find_child("InventoryPanel", true, false)
		if inventory:
			print("✅ InventoryPanel found dynamically!")
			return inventory
	print("❌ ERROR: InventoryPanel NOT found!")
	return null

# Equip item from inventory & update UI correctly
func equip_item_from_inventory(slot_type: String, item_name: String):
	if equipped_items.get(slot_type):
		print("❌ Slot already occupied:", slot_type)
		return

	print("✅ Equipping from inventory:", item_name, "to", slot_type)

	# ✅ Remove from inventory before equipping
	if GlobalState.inventory.has(item_name):
		GlobalState.inventory.erase(item_name)

	# ✅ Equip the item
	equipped_items[slot_type] = item_name
	GlobalState.equipped_items[slot_type] = item_name
	GlobalState.save_all_data()

	# ✅ Force UI update after equipping
	var slot = get_slot_by_type(slot_type)
	if slot:
		print("🎯 Updating UI for:", slot_type, "Slot:", slot)
		update_slot(slot, item_name)
	else:
		print("❌ ERROR: Slot not found for type:", slot_type)

	# ✅ **Ensure Inventory UI Updates**
	var inventory_panel = get_inventory_panel()
	if inventory_panel:
		print("✅ InventoryPanel found, updating UI...")
		inventory_panel.update_inventory()
	else:
		print("❌ ERROR: InventoryPanel not found!")





# ✅ **Find an available item in inventory for a specific slot**
func get_item_from_inventory(slot_type: String) -> String:
	for item in GlobalState.inventory.keys():
		var item_type = GlobalState.get_item_type(item)
		
		if slot_type == "weapon" and (item_type == "weapon" or item_type == "pickaxe"):
			return item  # ✅ Accepts both Weapons & Pickaxes
		elif slot_type == "helm" and item_type == "helm":
			return item
		elif slot_type == "chest" and item_type == "chest":
			return item
		elif slot_type == "legs" and item_type == "legs":
			return item
		elif slot_type == "shield" and item_type == "shield":
			return item
	return ""

func update_slot(slot: Button, item_name: String):
	if not slot:
		print("❌ ERROR: Slot reference is NULL!")
		return

	# ✅ Remove previous children (avoid duplicates)
	for child in slot.get_children():
		child.queue_free()

	# ✅ If an item is equipped, show the icon
	if item_name and item_name != "":
		var icon_texture = get_item_icon(item_name)
		if icon_texture:
			var icon_rect = TextureRect.new()
			icon_rect.texture = icon_texture
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_rect.custom_minimum_size = Vector2(64, 64)
			slot.add_child(icon_rect)

		# ✅ Ensure no text is displayed
		slot.text = ""

	else:
		# ✅ Ensure slot is empty with NO "[Empty]" message
		slot.text = ""  # ✅ No empty text
		print("✅ Slot now fully empty:", slot.name)



# Get the item icon for a given item name
func get_item_icon(item_name: String) -> Texture:
	var item_path = "res://assets/items/" + item_name + ".png"
	if FileAccess.file_exists(item_path):
		return load(item_path)  # Load the actual item icon
	else:
		print("⚠️ Missing icon for:", item_name)
		return load("res://assets/ui/default_item.png")  # Use a default icon

# ✅ **Returns the corresponding slot node**
func get_slot_by_type(slot_type: String) -> Button:
	match slot_type:
		"weapon":
			return weapon_slot
		"helm":
			return helm_slot
		"chest":
			return chest_slot
		"legs":
			return legs_slot
		"shield":
			return shield_slot
	return null

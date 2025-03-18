extends Control

@onready var helm_slot = $VBoxContainer/HelmSlot
@onready var chest_slot = $VBoxContainer/ChestRow/ChestSlot
@onready var weapon_slot = $VBoxContainer/ChestRow/WeaponSlot
@onready var shield_slot = $VBoxContainer/ChestRow/ShieldSlot
@onready var legs_slot = $VBoxContainer/LegsSlot

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
func load_equipped_items():
	# ✅ Ensure equipped_items is always a valid dictionary
	equipped_items = GlobalState.equipped_items if GlobalState.equipped_items else {}

	# ✅ Debugging: Print equipped items when loading UI
	print("📂 Loading Equipped Items in Armor Panel:", equipped_items)

	# ✅ Default values to prevent `null` issues
	var default_slots = {
		"weapon": "",
		"helm": "",
		"chest": "",
		"legs": "",
		"shield": "",
		"pickaxe": ""  # ✅ Pickaxe is included in case it's needed
	}

	# ✅ Replace `null` values with an empty string `""`
	for slot in default_slots.keys():
		if not equipped_items.has(slot) or equipped_items[slot] == null:
			equipped_items[slot] = default_slots[slot]

	# ✅ Update UI slots safely (prevents errors)
	update_slot(weapon_slot, equipped_items["weapon"])
	update_slot(helm_slot, equipped_items["helm"])
	update_slot(chest_slot, equipped_items["chest"])
	update_slot(legs_slot, equipped_items["legs"])
	update_slot(shield_slot, equipped_items["shield"])

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
func unequip_item(slot_type: String):
	var item = equipped_items[slot_type]
	if item:
		print("❎ Unequipping:", item, "from", slot_type)

		# ✅ Make sure item goes BACK into the inventory
		if GlobalState.inventory.has(item):
			GlobalState.inventory[item]["quantity"] += 1  # ✅ Add back the quantity
		else:
			GlobalState.inventory[item] = {"quantity": 1, "type": GlobalState.get_item_type(item)}

		# ✅ Remove item from equipped slot
		equipped_items[slot_type] = null
		GlobalState.equipped_items = equipped_items

		# ✅ Update UI Slot
		update_slot(get_slot_by_type(slot_type), "[Empty]")
		
		# ✅ Force an Inventory UI update to ensure the item appears back
		var inventory_panel = get_tree().get_root().get_node("MainUI/InventoryPanel")
		if inventory_panel:
			inventory_panel.update_inventory_ui()
			print("📌 Pickaxe returned to inventory.")

		GlobalState.save_all_data()


# ✅ Equip an item from inventory & update UI correctly
# ✅ Equip an item from inventory & update UI correctly
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
	GlobalState.equipped_items = equipped_items

	# ✅ Force UI update after equipping
	var slot = get_slot_by_type(slot_type)
	if slot:
		print("🎯 Updating UI for:", slot_type, "Slot:", slot)
		update_slot(slot, item_name)
	else:
		print("❌ ERROR: Slot not found for type:", slot_type)

	GlobalState.save_all_data()


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

# ✅ Update UI slot with the equipped item (removes EMPTY text)
func update_slot(slot: Button, item_name: String):
	if not slot:
		print("❌ ERROR: Slot reference is NULL!")
		return

	# ✅ Clear previous children to avoid duplicates
	for child in slot.get_children():
		child.queue_free()

	# ✅ If item exists, load its icon
	if item_name and typeof(item_name) == TYPE_STRING and item_name != "":
		var icon_texture = get_item_icon(item_name)

		if icon_texture:
			var icon_rect = TextureRect.new()
			icon_rect.texture = icon_texture
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_rect.custom_minimum_size = Vector2(64, 64)  # ✅ Adjust as needed
			slot.add_child(icon_rect)  # ✅ Add icon to slot
			print("📌 Displaying icon for:", item_name)
		else:
			print("⚠️ No icon found for:", item_name)

		# ✅ Ensure no text is displayed when an item is equipped
		slot.text = ""

	else:
		# ✅ No item equipped → Set to "[Empty]" with no icon
		slot.text = ""
		print("✅ Slot now empty:", slot.name)


func get_item_icon(item_name: String) -> Texture:
	var item_path = "res://assets/items/" + item_name + ".png"
	if FileAccess.file_exists(item_path):
		return load(item_path)  # ✅ Load the actual item icon
	else:
		print("⚠️ Missing icon for:", item_name)
		return load("res://assets/ui/default_item.png")  # ✅ Use a default icon


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

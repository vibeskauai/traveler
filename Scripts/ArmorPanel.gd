extends Control

@onready var helm_slot = $VBoxContainer/HelmSlot
@onready var chest_slot = $VBoxContainer/ChestRow/ChestSlot
@onready var weapon_slot = $VBoxContainer/ChestRow/WeaponSlot
@onready var shield_slot = $VBoxContainer/ChestRow/ShieldSlot
@onready var legs_slot = $VBoxContainer/LegsSlot

@onready var player = get_tree().get_first_node_in_group("player")
@onready var inventory_panel = get_tree().get_first_node_in_group("inventory_panel")
@onready var global_state = get_node("/root/GlobalState")  # Sync equipped items with save system
@onready var player_stats = get_node("/root/PlayerStats")

var equipped_items = {
	"weapon": null,
	"helm": null,
	"chest": null,
	"legs": null,
	"shield": null
}

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP  # Blocks clicks from reaching the game world
	load_equipped_items()
	player_stats.connect("equipment_changed", Callable(self, "_on_equipment_changed"))
	connect_slots()
func _on_equipment_changed(slot_type, item_name):
	update_slot(slot_type, item_name)  # ✅ Refresh UI when equipment changes

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
func update_ui():
	print("🔄 [PlayerStats] Updating UI after equip/unequip...")

	var armor_panel = get_tree().get_first_node_in_group("armor_ui")
	if armor_panel:
		print("✅ [PlayerStats] Found Armor Panel. Reloading UI...")
		armor_panel.load_equipped_items()
	else:
		print("❌ [PlayerStats] ERROR: ArmorPanel UI not found!")

	var inventory_panel = get_tree().get_first_node_in_group("inventory_ui")
	if inventory_panel:
		print("✅ [PlayerStats] Found Inventory Panel. Updating UI...")
		inventory_panel.update_inventory_ui()
	else:
		print("❌ [PlayerStats] ERROR: InventoryPanel UI not found!")



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
	print("✅ Equipping from inventory:", item_name, "to", slot_type)

	if player_stats.equipped_items.get(slot_type):
		print("❌ Slot already occupied:", slot_type)
		return

	# ✅ Remove from inventory before equipping
	if player_stats.inventory.has(item_name):
		player_stats.inventory.erase(item_name)

	# ✅ Equip the item
	player_stats.equipped_items[slot_type] = item_name
	global_state.save_all_data()

	# ✅ Update UI
	update_slot(get_slot_by_type(slot_type), item_name)

	print("✅ Finished equipping:", item_name)


func unequip_item(slot_type: String):
	print("🛠 [ArmorPanel] Called unequip_item() for:", slot_type)
	
	if not equipped_items.has(slot_type):
		print("❌ [ArmorPanel] ERROR: Slot does not exist in equipped_items:", slot_type)
		return

	var item = equipped_items[slot_type]
	if item:
		print("❎ [ArmorPanel] Unequipping:", item, "from", slot_type)

		# ✅ Ensure PlayerStats Handles Data Properly
		if player_stats:
			player_stats.unequip_item(slot_type)
		else:
			print("❌ [ArmorPanel] ERROR: PlayerStats not found!")

		# ✅ Refresh UI
		load_equipped_items()
	else:
		print("⚠️ [ArmorPanel] WARNING: No item to unequip in slot", slot_type)


func update_armor_ui():
	print("🔄 Updating Armor UI...")


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

func _on_slot_clicked(slot_type: String):
	print("🖱️ [ArmorPanel] Clicked slot:", slot_type)

	if equipped_items.get(slot_type):  
		print("❎ [ArmorPanel] Unequipping item from:", slot_type)
		player_stats.unequip_item(slot_type)  # ✅ Ensure unequip is actually called
		player.update_pickaxe_visibility()  # ✅ Ensure player sprite updates
	else:
		var item_name = get_item_from_inventory(slot_type)
		if item_name:
			print("✅ [ArmorPanel] Equipping:", item_name)
			player_stats.equip_item(slot_type, item_name)
			player.update_pickaxe_visibility()
		else:
			print("❌ [ArmorPanel] ERROR: No item found in inventory for slot", slot_type)

	# ✅ Ensure slot was actually unequipped
	if not equipped_items.get(slot_type):
		print("✅ [ArmorPanel] Slot", slot_type, "is now empty.")
	else:
		print("⚠️ [ArmorPanel] Slot", slot_type, "still has:", equipped_items[slot_type])


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

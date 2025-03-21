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
	
func load_item_resource(path: String) -> ItemResource:
	if path != "":
		var item = load(path)
		if item is ItemResource:
			return item
	return null

func _on_equipment_changed(slot_type: String, item_path: String):
	var item_resource = load_item_resource(item_path)
	update_slot(get_slot_by_type(slot_type), item_resource)

func load_equipped_items():
	equipped_items = GlobalState.equipped_items if GlobalState.equipped_items else {}

	var default_slots = {
		"weapon": "",
		"helm": "",
		"chest": "",
		"legs": "",
		"shield": "",
		"pickaxe": ""
	}

	for slot in default_slots.keys():
		if !equipped_items.has(slot) or equipped_items[slot] == null:
			equipped_items[slot] = default_slots[slot]

	# Load each item as a resource and pass it to update_slot
	update_slot(weapon_slot, load_item_resource(equipped_items["weapon"]))
	update_slot(helm_slot, load_item_resource(equipped_items["helm"]))
	update_slot(chest_slot, load_item_resource(equipped_items["chest"]))
	update_slot(legs_slot, load_item_resource(equipped_items["legs"]))
	update_slot(shield_slot, load_item_resource(equipped_items["shield"]))

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

func equip_item_from_inventory(slot_type: String, item_path: String):
	print("✅ Equipping from inventory:", item_path, "to", slot_type)

	if player_stats.equipped_items.get(slot_type):
		print("❌ Slot already occupied:", slot_type)
		return

	# ✅ Remove item from inventory array
	for i in range(player_stats.inventory.size()):
		if player_stats.inventory[i].path == item_path:
			player_stats.inventory.remove_at(i)
			break

	# ✅ Equip using path
	player_stats.equipped_items[slot_type] = item_path
	global_state.save_all_data()

	var item_resource = load_item_resource(item_path)
	update_slot(get_slot_by_type(slot_type), item_resource)

	print("✅ Finished equipping:", item_path)



func unequip_item(slot_type: String):
	print("🛠 [ArmorPanel] Called unequip_item() for:", slot_type)
	
	var item_path = equipped_items.get(slot_type, "")
	if item_path != "":
		print("❎ Unequipping:", item_path)

		if player_stats:
			player_stats.unequip_item(slot_type)

			# ✅ Add item back to inventory
			player_stats.add_item_to_inventory(load_item_resource(item_path))
		else:
			print("❌ PlayerStats not found.")

		load_equipped_items()
	else:
		print("⚠️ Nothing to unequip in", slot_type)



func update_armor_ui():
	print("🔄 Updating Armor UI...")


func update_slot(slot: Button, item: ItemResource):
	if not slot:
		return

	for child in slot.get_children():
		child.queue_free()

	if item:
		var icon_texture = item.icon
		if icon_texture:
			var icon_rect = TextureRect.new()
			icon_rect.texture = icon_texture
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_rect.custom_minimum_size = Vector2(64, 64)
			slot.add_child(icon_rect)

		slot.text = ""
	else:
		slot.text = ""
		print("✅ Slot now fully empty:", slot.name)



func _on_slot_clicked(slot_type: String):
	print("🖱️ [ArmorPanel] Clicked slot:", slot_type)

	var equipped_path = equipped_items.get(slot_type, "")
	if equipped_path != "":
		print("❎ Unequipping:", equipped_path)
		player_stats.unequip_item(slot_type)
		player.update_pickaxe_visibility()
	else:
		var item_path = get_item_path_from_inventory(slot_type)
		if item_path != "":
			print("✅ Equipping:", item_path)
			player_stats.equip_item(slot_type, item_path)
			player.update_pickaxe_visibility()
		else:
			print("❌ No valid item in inventory for:", slot_type)

	if equipped_items.get(slot_type, "") == "":
		print("✅ Slot", slot_type, "is now empty.")
	else:
		print("⚠️ Slot", slot_type, "still has:", equipped_items[slot_type])



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

func get_item_path_from_inventory(slot_type: String) -> String:
	for entry in GlobalState.inventory:
		if entry.has("path"):
			var item = load_item_resource(entry["path"])
			if item:
				var match_slot = item.equip_slot
				if slot_type == "weapon" and (match_slot == "weapon" or match_slot == "pickaxe"):
					return entry["path"]
				elif match_slot == slot_type:
					return entry["path"]
	return ""

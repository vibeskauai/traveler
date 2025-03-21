extends Panel

@onready var global_state = get_node("/root/GlobalState")
@onready var player_stats = get_node("/root/PlayerStats")
@onready var inventory_grid = $InventoryPanel/GridContainer
@onready var armor_panel = get_node("/root/TheCrossroads/MainUI/ArmorPanel")

@onready var inventory_panel: Control = null

const TOTAL_SLOTS = 28
var equipped_item_path: String = ""

# 🔁 Refresh inventory after loading
func _ready():
	print("🔄 [Inventory] Updating UI after game load...")
	player_stats.connect("inventory_updated", Callable(self, "_on_inventory_updated"))
	player_stats.inventory = GlobalState.inventory

	inventory_panel = get_tree().get_root().find_child("InventoryPanel", true, false)
	if inventory_panel:
		print("✅ InventoryPanel found dynamically!")
		update_inventory_ui()
	else:
		print("❌ InventoryPanel not found!")

	if inventory_panel and inventory_panel.has_node("GridContainer"):
		inventory_grid = inventory_panel.get_node("GridContainer")
		print("✅ GridContainer loaded.")
	else:
		print("❌ GridContainer not found in InventoryPanel.")

# 🔁 Called when inventory updates
func _on_inventory_updated():
	update_inventory_ui()

# 🔄 Refresh the full inventory UI
func update_inventory_ui():
	print("🔄 Updating Inventory UI...")

	if not inventory_grid:
		print("❌ Inventory grid missing.")
		return

	for child in inventory_grid.get_children():
		child.queue_free()

	for entry in player_stats.inventory:
		if entry.has("path") and entry.has("quantity"):
			var item = load(entry.path) as ItemResource
			if item:
				add_item_button(item, entry.quantity)

	print("✅ Inventory UI refreshed.")

# 🔘 Add a button to the inventory for a given item and quantity
func add_item_button(item: ItemResource, quantity: int):
	var item_button = Button.new()
	item_button.text = ""
	item_button.custom_minimum_size = Vector2(58, 58)
	item_button.flat = true
	item_button.focus_mode = Control.FOCUS_NONE
	item_button.name = item.item_name

	# Connect the full item resource to the pressed signal
	item_button.connect("pressed", Callable(self, "_on_item_button_pressed").bind(item))

	# Icon
	var icon_rect = TextureRect.new()
	icon_rect.stretch_mode = TextureRect.STRETCH_SCALE
	icon_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon_rect.offset_left = -5
	icon_rect.offset_top = -5
	icon_rect.offset_right = -10
	icon_rect.offset_bottom = -10
	icon_rect.texture = item.icon
	item_button.add_child(icon_rect)

	# Quantity label (only for stackables)
	if !item.can_equip and quantity > 1:
		var count_label = Label.new()
		count_label.text = str(quantity)
		count_label.add_theme_font_size_override("font_size", 14)
		count_label.add_theme_color_override("font_color", Color(1, 1, 1))
		count_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))

		var label_container = Control.new()
		label_container.add_child(count_label)
		label_container.anchor_left = 0.0
		label_container.anchor_top = 0.0
		label_container.anchor_right = 0.0
		label_container.anchor_bottom = 0.0
		count_label.position = Vector2(-5, -5)
		count_label.z_index = 2
		item_button.add_child(label_container)

	inventory_grid.add_child(item_button)
	print("🧱 Added item to UI:", item.item_name)

# 🖱️ Handle clicking on an inventory item
func _on_item_button_pressed(item: ItemResource):
	print("🖱️ Clicked item:", item.item_name)

	if not player_stats:
		print("❌ PlayerStats missing!")
		return

	var equipped = equipped_item_path == item.resource_path
	if equipped:
		print("🔄 Unequipping:", item.item_name)
		player_stats.unequip_item(item.equip_slot)
		equipped_item_path = ""
	else:
		if item.can_equip:
			print("✅ Equipping:", item.item_name)
			player_stats.equip_item(item.equip_slot, item.resource_path)
			equipped_item_path = item.resource_path
		else:
			print("ℹ️ Item is not equippable:", item.item_name)

	update_inventory_ui()
	GlobalState.save_all_data()

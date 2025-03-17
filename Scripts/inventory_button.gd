extends Button

@onready var inventory_panel = get_node("/root/TheCrossroads/MainUI/InventoryPanel")
@onready var inventory_button = $InventoryButton  # The button node

func _ready():
	# Ensure the inventory panel is not null
	if inventory_panel:
		self.connect("pressed", Callable(self, "_on_inventory_button_pressed"))
	else:
		print("Error: Inventory panel is missing!")

func _on_inventory_button_pressed():
	if inventory_panel:
		inventory_panel.visible = !inventory_panel.visible
	else:
		print("Error: Inventory panel is still null!")

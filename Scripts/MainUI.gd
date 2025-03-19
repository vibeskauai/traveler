extends Node

@onready var inventory_panel = get_node_or_null("InventoryPanel")  # ✅ Prevents null errors
@onready var stats_panel = get_node_or_null("StatsPanel")
@onready var armor_panel = get_node_or_null("ArmorPanel")


@onready var inventory_button = $InventoryButton
@onready var skills_button = $SkillsButton
@onready var armor_button = $ArmorButton

func _ready():
	# Ensure all panels are found before modifying visibility
	if inventory_panel:
		inventory_panel.visible = true  # ✅ Only set visible if found
	else:
		print("❌ ERROR: InventoryPanel not found in MainUI.gd!")

	if stats_panel:
		stats_panel.visible = false
	else:
		print("❌ ERROR: StatsPanel not found in MainUI.gd!")

	if armor_panel:
		armor_panel.visible = false
	else:
		print("❌ ERROR: ArmorPanel not found in MainUI.gd!")


	# Connect the button signals
	inventory_button.connect("pressed", Callable(self, "_on_inventory_button_pressed"))
	skills_button.connect("pressed", Callable(self, "_on_skills_button_pressed"))
	armor_button.connect("pressed", Callable(self, "_on_armor_button_pressed"))

# Inventory button pressed
func _on_inventory_button_pressed():
	_switch_panel(inventory_panel)

# Skills button pressed
func _on_skills_button_pressed():
	_switch_panel(stats_panel)

# Armor button pressed
func _on_armor_button_pressed():
	_switch_panel(armor_panel)

# Helper function to switch between panels
func _switch_panel(panel_to_show: Panel):
	inventory_panel.visible = false
	stats_panel.visible = false
	armor_panel.visible = false

	panel_to_show.visible = true  # Show the selected panel

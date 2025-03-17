extends Node

@onready var inventory_panel = $InventoryPanel
@onready var stats_panel = $StatsPanel
@onready var armor_panel = $ArmorPanel

@onready var inventory_button = $InventoryButton
@onready var skills_button = $SkillsButton
@onready var armor_button = $ArmorButton

func _ready():
	# Set the panels' initial visibility
	inventory_panel.visible = true  # Make Inventory the default visible panel
	stats_panel.visible = false
	armor_panel.visible = false

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

extends Node

@onready var inventory_panel = get_node_or_null("InventoryPanel")  # ✅ Prevents null errors
@onready var stats_panel = get_node_or_null("StatsPanel")
@onready var armor_panel = get_node_or_null("ArmorPanel")

@onready var inventory_button = $InventoryButton
@onready var skills_button = $SkillsButton
@onready var armor_button = $ArmorButton

var is_ui_focused := false  # Tracks if the UI is currently active

func _ready():
	# Connect button presses to track when UI is in use
	for button in get_tree().get_nodes_in_group("ui_buttons"):
		button.connect("pressed", Callable(self, "_on_ui_pressed"))
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

func _on_ui_pressed():
	is_ui_focused = true
	await get_tree().create_timer(0.1).timeout  # Small delay to avoid blocking everything
	is_ui_focused = false  # Reset after interaction

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if _is_click_on_ui(event):
			get_viewport().set_input_as_handled()  # Prevents event from affecting the game

func _is_click_on_ui(event: InputEventMouseButton) -> bool:
	var mouse_pos = get_viewport().get_mouse_position()
	
	for ui_element in get_tree().get_nodes_in_group("ui_panels"):  # Make sure UI elements are in this group
		if ui_element.visible and ui_element.get_global_rect().has_point(mouse_pos):
			return true  # Clicked inside a UI element

	return false  # Clicked outside UI

func is_ui_blocked(event: InputEvent = null) -> bool:
	if inventory_panel.visible or stats_panel.visible or armor_panel.visible:
		return true  # UI is open, block game input
	return false

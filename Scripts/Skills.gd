extends Panel

# References to UI elements
@onready var total_level_label: Label = $TotalLevelLabel
@onready var stats_container: VBoxContainer = $StatsContainer

# Optional: Direct row references (if needed)
@onready var mining_row: VBoxContainer = $StatsContainer/MiningRow
@onready var herbalism_row: VBoxContainer = $StatsContainer/HerbalismRow
@onready var combat_row: VBoxContainer = $StatsContainer/CombatRow
@onready var mining_progress_node: ProgressBar = $StatsContainer/MiningRow/ProgressBar

func _ready():
	# Center the StatsPanel with a fixed size (400x300) manually:
	custom_minimum_size = Vector2(300, 400)
	
	# ---- Total Level Label (Header) ----
	# Set the header to span the top of the panel.
	total_level_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	total_level_label.offset_top = 55   # Top offset
	total_level_label.offset_left = 50   # Left offset
	total_level_label.offset_right = -50   # Right offset (negative means inset)
	total_level_label.custom_minimum_size = Vector2(0, 40)  # Set minimum height
	
	# ---- Stats Container (VBoxContainer) ----
	# The container that holds all the skill rows will fill the rest of the panel.
	stats_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Set its top offset so it begins below the header (header height + some spacing)
	stats_container.offset_top = total_level_label.custom_minimum_size.y + 80

	stats_container.offset_left = 30
	stats_container.offset_right = -30
	stats_container.offset_bottom = -10
	# Optional: Set spacing between rows (using the setter method)
	stats_container.set("spacing", 10)
	
	# ---- Skill Rows (HBoxContainers) ----
	# Optionally, ensure each row has a minimum height
	for row in stats_container.get_children():
		if row is HBoxContainer:
			var current_min: Vector2 = row.custom_minimum_size
			row.custom_minimum_size = Vector2(current_min.x, 40)  # Set minimum height to 40 pixels
	
	# Now update the stats from PlayerStats
	update_stats()

func update_stats():
	# Update the header with the total level (assuming PlayerStats is an autoload)
	total_level_label.text = "Total Level: " + str(PlayerStats.total_level)
	
	# Update Mining row
	var mining_label: Label = stats_container.get_node_or_null("MiningRow/MiningLabel")
	var mining_progress: ProgressBar = stats_container.get_node_or_null("MiningRow/ProgressBar")
	if mining_label:
		mining_label.text = "Mining: Level " + str(PlayerStats.mining_level) + "/20"
	else:
		print("DEBUG: MiningLabel not found at path 'MiningRow/MiningLabel'")
	if mining_progress:
		mining_progress.value = int(PlayerStats.mining_xp) % 100
		mining_progress.max_value = 100
	else:
		print("DEBUG: MiningProgressBar not found at path 'MiningRow/MiningProgressBar'")
	
	# Update Herbalism row
	var herbalism_label: Label = stats_container.get_node_or_null("HerbalismRow/HerbalismLabel")
	var herbalism_progress: ProgressBar = stats_container.get_node_or_null("HerbalismRow/ProgressBar")
	if herbalism_label:
		herbalism_label.text = "Herbalism: Level " + str(PlayerStats.herbalism_level) + "/20"
	else:
		print("DEBUG: HerbalismLabel not found at path 'HerbalismRow/HerbalismLabel'")
	if herbalism_progress:
		herbalism_progress.value = int(PlayerStats.herbalism_xp) % 100
		herbalism_progress.max_value = 100
	else:
		print("DEBUG: HerbalismProgressBar not found at path 'HerbalismRow/HerbalismProgressBar'")
	
	# Update Combat row
	var combat_label: Label = stats_container.get_node_or_null("CombatRow/CombatLabel")
	var combat_progress: ProgressBar = stats_container.get_node_or_null("CombatRow/ProgressBar")
	if combat_label:
		combat_label.text = "Combat: Level " + str(PlayerStats.combat_level) + "/20"
	else:
		print("DEBUG: CombatLabel not found at path 'CombatRow/CombatLabel'")
	if combat_progress:
		combat_progress.value = int(PlayerStats.combat_xp) % 100
		combat_progress.max_value = 100
	else:
		print("DEBUG: CombatProgressBar not found at path 'CombatRow/CombatProgressBar'")

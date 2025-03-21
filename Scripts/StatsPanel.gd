extends Panel

# References to UI elements
@onready var total_level_label: Label = $TotalLevelLabel
@onready var stats_container: VBoxContainer = $StatsContainer

# Optional: Direct row references (if needed)
@onready var mining_row: VBoxContainer = $StatsContainer/MiningRow
@onready var herbalism_row: VBoxContainer = $StatsContainer/HerbalismRow
@onready var combat_row: VBoxContainer = $StatsContainer/CombatRow
@onready var mining_progress_node: ProgressBar = $StatsContainer/MiningRow/ProgressBar

# Reference to SkillStats (Autoload or from the scene)
@onready var skill_stats = SkillStats  # Accessing the Autoloaded SkillStats instance

# AudioStreamPlayer references for level-up sounds
@onready var mining_levelup_sound: AudioStreamPlayer2D = $MiningLevelUpSound
@onready var herbalism_levelup_sound: AudioStreamPlayer2D = $HerbalismLevelUpSound
@onready var combat_levelup_sound: AudioStreamPlayer2D = $CombatLevelUpSound

func _ready():
	# Ensure game data is loaded
	GlobalState.load_game_data()

	# Connect the xp_updated and level_up signals to their respective functions
	skill_stats.connect("xp_updated", Callable(self, "_on_xp_updated"))
	skill_stats.connect("level_up", Callable(self, "_on_level_up"))  # Connect level-up signal
	
	# Center the StatsPanel with a fixed size (400x300)
	custom_minimum_size = Vector2(300, 400)
	
	# ---- Total Level Label (Header) ----
	total_level_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	total_level_label.offset_top = 55
	total_level_label.offset_left = 50
	total_level_label.offset_right = -50
	total_level_label.custom_minimum_size = Vector2(0, 40)
	
	# ---- Stats Container (VBoxContainer) ----
	stats_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stats_container.offset_top = total_level_label.custom_minimum_size.y + 80
	stats_container.offset_left = 30
	stats_container.offset_right = -30
	stats_container.offset_bottom = -10
	stats_container.set("spacing", 10)
	
	# ---- Skill Rows (VBoxContainers) ----
	for row in stats_container.get_children():
		if row is HBoxContainer:
			var current_min: Vector2 = row.custom_minimum_size
			row.custom_minimum_size = Vector2(current_min.x, 40)
	
	# Update the stats from SkillStats
	update_stats()

# Function to update stats on the UI
func update_stats():
	# Update the total level label from GlobalState or PlayerStats
	total_level_label.text = "Total Level: " + str(PlayerStats.total_level)

	# Update Mining row
	var mining_label: Label = stats_container.get_node_or_null("MiningRow/MiningLabel")
	var mining_progress: ProgressBar = stats_container.get_node_or_null("MiningRow/ProgressBar")
	if mining_label:
		mining_label.text = "Mining: Level " + str(skill_stats.get_skill_level("mining")) + "/20"
	if mining_progress:
		mining_progress.value = int(skill_stats.mining_xp) % 100  # Update progress bar value
		mining_progress.max_value = 100  # Set max value for progress bar
	
	# Update Herbalism row
	var herbalism_label: Label = stats_container.get_node_or_null("HerbalismRow/HerbalismLabel")
	var herbalism_progress: ProgressBar = stats_container.get_node_or_null("HerbalismRow/ProgressBar")
	if herbalism_label:
		herbalism_label.text = "Herbalism: Level " + str(skill_stats.get_skill_level("herbalism")) + "/20"
	if herbalism_progress:
		herbalism_progress.value = int(skill_stats.herbalism_xp) % 100
		herbalism_progress.max_value = 100
	
	# Update Combat row
	var combat_label: Label = stats_container.get_node_or_null("CombatRow/CombatLabel")
	var combat_progress: ProgressBar = stats_container.get_node_or_null("CombatRow/ProgressBar")
	if combat_label:
		combat_label.text = "Combat: Level " + str(skill_stats.get_skill_level("combat")) + "/20"
	if combat_progress:
		combat_progress.value = int(skill_stats.combat_xp) % 100
		combat_progress.max_value = 100

func _on_level_up(skill: String, new_level: int):
	print(skill + " has leveled up to level " + str(new_level))

	# Play the corresponding level-up sound based on the skill
	if skill == "mining":
		mining_levelup_sound.play()  # Play mining level-up sound
	elif skill == "herbalism":
		herbalism_levelup_sound.play()  # Play herbalism level-up sound
	elif skill == "combat":
		combat_levelup_sound.play()  # Play combat level-up sound

# Function to handle XP updates
func _on_xp_updated():
	update_stats()  # Update the stats when XP changes

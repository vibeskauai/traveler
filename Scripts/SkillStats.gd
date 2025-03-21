extends Node

# XP Storage (mining, herbalism, combat)
var mining_xp = 0
var herbalism_xp = 0
var combat_xp = 0

# Level Calculation
var mining_level = 1
var herbalism_level = 1
var combat_level = 1

# Max level for each skill
var max_skill_level = 20

signal xp_updated  # Signal for UI updates
signal level_up  # Signal for skill level up event

# Called when the game starts
func _ready():
	print("🗂️ [SkillStats] Initialized XP and Level data.")
	load_data()  # Load the XP data on startup

# Function to add XP for a specific skill
func add_xp(skill: String, amount: int):
	match skill:
		"mining":
			mining_xp += amount
		"herbalism":
			herbalism_xp += amount
		"combat":
			combat_xp += amount
		_:
			print("❌ Error: Unknown skill for XP gain!")

	# Emit signal to notify about XP change
	emit_signal("xp_updated")
	check_level_up(skill)  # Check if the skill leveled up

# Function to check if a skill has leveled up
func check_level_up(skill: String):
	var xp_needed = get_xp_for_next_level(skill)
	var current_xp = 0
	var current_level = 0

	match skill:
		"mining":
			current_xp = mining_xp
			current_level = get_skill_level("mining")
		"herbalism":
			current_xp = herbalism_xp
			current_level = get_skill_level("herbalism")
		"combat":
			current_xp = combat_xp
			current_level = get_skill_level("combat")

	# If XP exceeds required XP for the next level and skill hasn't reached max level
	if current_xp >= xp_needed and current_level < max_skill_level:
		current_level += 1
		print(skill + " leveled up to level " + str(current_level))
		emit_signal("level_up", skill, current_level)  # Emit signal for level up

	# Update levels after checking for level up
	update_levels()

# Function to update levels based on current XP values
func update_levels():
	mining_level = min(int(mining_xp / 100) + 1, max_skill_level)
	herbalism_level = min(int(herbalism_xp / 100) + 1, max_skill_level)
	combat_level = min(int(combat_xp / 100) + 1, max_skill_level)

	# Debugging: Show the updated levels
	print("🗂️ [SkillStats] Levels Updated:")
	print("Mining Level:", mining_level)
	print("Herbalism Level:", herbalism_level)
	print("Combat Level:", combat_level)

# Function to get the current skill level
func get_skill_level(skill: String) -> int:
	match skill:
		"mining":
			return min(int(mining_xp / 100) + 1, max_skill_level)
		"herbalism":
			return min(int(herbalism_xp / 100) + 1, max_skill_level)
		"combat":
			return min(int(combat_xp / 100) + 1, max_skill_level)
	return 0  # Return 0 if skill is unknown

# Function to get XP needed for the next level for a given skill
func get_xp_for_next_level(skill: String) -> int:
	return 100 * (get_skill_level(skill) + 1)  # Adjust the XP formula if needed

# Sync XP and levels to GlobalState
func sync_with_global_state():
	GlobalState.mining_xp = mining_xp
	GlobalState.herbalism_xp = herbalism_xp
	GlobalState.combat_xp = combat_xp
	GlobalState.mining_level = mining_level
	GlobalState.herbalism_level = herbalism_level
	GlobalState.combat_level = combat_level

	# Save to GlobalState
	GlobalState.save_all_data()
	print("✅ [SkillStats] Synced with GlobalState.")

# Function to load XP and Level data (called on game start)
func load_data():
	if GlobalState.is_game_loaded:
		mining_xp = GlobalState.mining_xp
		herbalism_xp = GlobalState.herbalism_xp
		combat_xp = GlobalState.combat_xp
		update_levels()  # Ensure the levels are updated based on loaded XP
		print("🗂️ [SkillStats] Loaded data from GlobalState.")

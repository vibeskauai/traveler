extends StaticBody2D  # Keeps ore solid and interactable

@onready var player = get_tree().get_first_node_in_group("player")
@onready var player_stats = PlayerStats 
@export var ore_type: String = "copper_ore"  # Default is copper_ore, but this will be set dynamically
@onready var sprite := $Sprite2D
@onready var hitbox := $Hitbox as Area2D  # Detects swings
@onready var pop_up_label := $PopUpLabel  # Shows mining restrictions
@onready var hit_sound = $HitSound if has_node("HitSound") else null  # Reference to the AudioStreamPlayer
@onready var break_sound = $BreakSound if has_node("BreakSound") else null  # Sound for breaking ore
@export var collision_removal_delay: float = 0.05  # Delay before removing collision
@export var ore_removal_delay: float = 0.1  # Time before fully removing ore
var swing_cooldown = 0.5  # Cooldown time for swing in seconds
var swing_timer = 0.0  # Cooldown timer

@onready var main_ui := get_tree().get_first_node_in_group("main_ui")

# Ore health values
var ore_health_values := {
	"copper_ore": 10,  
	"silver_ore": 20,  
	"gold_ore": 60,  
	"rune_ore": 100,   
	"dragon_ore": 200  
}

# Required mining levels
var required_mining_level := {
	"copper_ore": 1,   
	"silver_ore": 5,   
	"gold_ore": 10,    
	"rune_ore": 15,   
	"dragon_ore": 20  
}

# Dictionary defining ore drop ranges
var drop_amounts = {
	"copper_ore": [1, 2],    # Drops between 1-2
	"silver_ore": [1, 3],    # Drops between 1-3
	"gold_ore": [2, 4],      # Drops between 2-4
	"rune_ore": [2, 5],      # Drops between 2-5
	"dragon_ore": [3, 6]     # Drops between 3-6
}

# XP values per ore type
var xp_per_hit := {
	"copper_ore": 2,  
	"silver_ore": 3,
	"gold_ore": 5,
	"rune_ore": 7,   
	"dragon_ore": 20  
}

var xp_on_break := {
	"copper_ore": 10,    
	"silver_ore": 15,
	"gold_ore": 25,
	"rune_ore": 50,   
	"dragon_ore": 100 
}

var pickaxe_damage_values := {
	"Hollowed Pickaxe": 1,
	"Copper Infused Pickaxe": 2,
	"Silver Infused Pickaxe": 3,
	"Gold Infused Pickaxe": 4,
	"Rune Infused Pickaxe": 5,
	"Dragon Pickaxe": 10
}

var ore_health: int  
var is_destroyed := false  # Prevents multiple break events
var being_mined := false  # Track if the ore is being mined

func _ready():
	# Check if the ore was previously mined based on position (in GlobalState)
	if GlobalState.is_ore_mined(global_position):
		queue_free()  # If it's already mined, don't instantiate it in the scene
		return
		
		add_to_group("ores")

	# Ensure ore_type is set properly
	if ore_type.is_empty():
		ore_type = "copper_ore"  

	if not ore_type.ends_with("_ore"):
		ore_type += "_ore"

	# Set initial ore health based on ore type (from ore_health_values only)
	ore_health = ore_health_values.get(ore_type, 10)  # Default to 10 if not found

	# Debug print to show ore health
	print("Updated Ore Health for", ore_type, "is:", ore_health)

	# Ensure the hitbox is connected to detect player interaction
	if hitbox:
		hitbox.connect("area_entered", Callable(self, "_on_hit"))

	# Dynamically update ore_type based on the texture name (fixing the `has_data()` error)
	if sprite.texture:
		var texture_name = sprite.texture.get_name().to_lower().replace(" ", "_")
		ore_type = texture_name + "_ore"  # Update the ore_type dynamically based on the sprite texture
		print("Ore type dynamically set to:", ore_type)


# **Handle Ore Click**
func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		print("🖱️ OreNode clicked:", ore_type)
		var player = get_tree().get_first_node_in_group("player")
		if player:
			player.move_to_ore(self)  # Player auto-walks to ore

# Function to handle mining interaction with the ore
func start_mining(player):
	if being_mined or is_destroyed:
		return  # Prevent mining if already being mined or destroyed
	
	being_mined = true
	print("⛏️ Auto-mining started on", ore_type)

	# Call mining function to continue
	mine_ore(player)

# Mine the ore with the player
func mine_ore(pickaxe: Node):
	# Get the player node from the group 'player'
	var player = get_tree().get_first_node_in_group("player")  # Ensure player is in the group 'player'
	
	if not player:
		print("❌ Player node not found!")
		return  # Exit function if player is not found
	
	# Get the equipped pickaxe using the get_equipped_item function from PlayerStats
	var equipped_pickaxe = player.player_stats.get_equipped_item("pickaxe")
	
	if equipped_pickaxe == "None":
		print("❌ No pickaxe equipped! Cannot mine ore.")
		return  # Exit function if no pickaxe is equipped

	# Proceed with mining if pickaxe is equipped and ore health is greater than 0
	if ore_health > 0:
		# Retrieve the damage value for the equipped pickaxe from the pickaxe_damage_values dictionary
		var damage = pickaxe_damage_values.get(equipped_pickaxe, 1)  # Default to damage of 1 if not found
		ore_health -= damage  # Decrease ore health based on pickaxe damage
		print("Ore health after mining:", ore_health)

		# Check if ore health reaches 0, and then break the ore
		if ore_health <= 0:
			break_ore()  # Call break_ore to handle ore destruction
		else:
			print("Ore health is not yet 0, continue mining.")
	else:
		print("Ore is already destroyed or can't be mined anymore.")

	# Play the hit sound when ore is mined (if the sound exists)
	if hit_sound:
		hit_sound.play()  # Play the mining sound when the ore is mined


# Break the ore when health reaches 0
func break_ore():
	if is_destroyed:
		return  # Prevent breaking ore multiple times

	is_destroyed = true
	print("🪨 Ore destroyed!")

	# Give XP for breaking the ore
	var xp_gain = xp_on_break.get(ore_type, 0)
	PlayerStats.gain_xp("mining", xp_gain)

	# Randomly determine the amount of ore to drop
	var drop_range = drop_amounts.get(ore_type, [1, 1])  # Default to [1,1] if ore_type is not found
	var drop_amount = randi_range(drop_range[0], drop_range[1])  # Random number between min and max

	# Add ore to inventory
	var ore_name = ore_type.replace("_ore", "").capitalize()  # Example: "Copper Ore"
	if GlobalState.inventory.has(ore_name):
		GlobalState.inventory[ore_name]["quantity"] += drop_amount
	else:
		GlobalState.inventory[ore_name] = {"quantity": drop_amount, "type": "ore"}

	print("📌 Added", drop_amount, ore_name, "to inventory!")

	# Hide the ore sprite immediately before it is removed from the scene
	sprite.visible = false

	# Play break sound with a slight delay
	if break_sound and is_inside_tree():
		break_sound.play()
		await break_sound.finished  # Ensure sound finishes before removing the ore

	# Save the ore as mined in GlobalState
	GlobalState.save_mined_ore(global_position, ore_type)

	# Remove the ore from the scene
	await get_tree().create_timer(collision_removal_delay).timeout
	queue_free()  # Destroy the ore node after it's mined

extends StaticBody2D  # Keeps ore solid and interactable

@export var ore_type: String = "copper_ore" 
@export var drop_amount: int = 1

@onready var sprite := $Sprite2D
@onready var hitbox := $Hitbox as Area2D  # Detects swings
@onready var pop_up_label := $PopUpLabel  # Shows mining restrictions
@onready var hit_sound := $HitSound if has_node("HitSound") else null  # Sound for hitting ore
@onready var break_sound := $BreakSound if has_node("BreakSound") else null  # Sound for breaking ore
@export var collision_removal_delay: float = 0.05  # Delay before removing collision
@export var ore_removal_delay: float = 0.1  # Time before fully removing ore
var swing_cooldown = 0.5  # Cooldown time for swing in seconds
var swing_timer = 0.0  # Cooldown timer


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

var ore_health: int  
var is_destroyed := false  # Prevents multiple break events
var being_mined := false  # Track if the ore is being mined

func _ready():
	# Check if the ore was previously mined based on position (in GlobalState)
	if GlobalState.is_ore_mined(global_position):
		queue_free()  # If it's already mined, don't instantiate it in the scene
		return
		
		add_to_group("ore")

	# Ensure ore_type is set properly
	if ore_type.is_empty():
		ore_type = "copper_ore"  

	if not ore_type.ends_with("_ore"):
		ore_type += "_ore"

	ore_health = ore_health_values.get(ore_type, 10)

	if hitbox:
		hitbox.connect("area_entered", Callable(self, "_on_hit"))

# Function to handle mining interaction with the ore
func start_mining(player):
	if being_mined or is_destroyed:
		return  # Prevent mining if already being mined or destroyed
	
	being_mined = true
	print("⛏️ Auto-mining started on", ore_type)

	# Call mining function to continue
	mine_ore(player)

# Mine the ore with the player
func mine_ore(player):
	if not being_mined or is_destroyed or ore_health <= 0 or player.velocity.length() > 0:
		print("⛏️ Mining STOPPED due to movement or ore destruction.")  
		being_mined = false
		return  

	print("⛏️ Mining CONTINUES - being_mined:", being_mined)

	# Trigger mining animation
	player.play_mining_animation()

	var mining_damage = player.pickaxe_damage
	ore_health -= mining_damage
	print("🪨 Ore hit! Remaining health:", ore_health, "(Damage dealt:", mining_damage, ")")

	if hit_sound:
		hit_sound.play()

	# Award XP for each hit
	var xp_gain = xp_per_hit.get(ore_type, 0)
	PlayerStats.gain_xp("mining", xp_gain)

	# If ore health is less than or equal to 0, break the ore and remove it from the game
	if ore_health <= 0:
		break_ore()

		# Stop mining once ore is destroyed
		being_mined = false
		return

	# Wait for the next mining action to proceed (using swing_timer)
	if swing_timer > 0:
		return  # Wait if we're still in the cooldown period

	# Start the cooldown after mining
	swing_timer = swing_cooldown

	# Stop mining if the player moves after the timer
	if not being_mined or player.velocity.length() > 0:
		print("⛏️ Mining canceled due to movement.")
		being_mined = false
		return

	# Continue mining as long as the ore hasn't been destroyed and player is not moving
	mine_ore(player)  # Continue mining if conditions are met



# Break the ore when health reaches 0
func break_ore():
	if is_destroyed:
		return  # Prevent multiple break events

	is_destroyed = true
	print("🪨 Ore destroyed!")


	# Play break sound
	if break_sound and is_inside_tree():
		break_sound.play()
		await break_sound.finished  # Wait for the sound to finish

	# Save the ore as mined in GlobalState
	GlobalState.save_mined_ore(global_position, ore_type)

	await get_tree().create_timer(collision_removal_delay).timeout
	queue_free()  # Destroy the ore from the scene

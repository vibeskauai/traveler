extends StaticBody2D  # Keeps ore solid and interactable

@onready var player = get_tree().get_first_node_in_group("player")  # Get the player node
@onready var player_stats = get_node("/root/PlayerStats")  # Reference to PlayerStats
@onready var global_state = get_node("/root/GlobalState")  # Reference to GlobalState
@onready var inventory_panel = get_node("/root/MainUI/InventoryPanel")  # Reference to Inventory UI panel
@onready var sprite := $Sprite2D  # Ore sprite
@onready var hitbox := $Hitbox as Area2D  # Detects swings
@onready var hit_sound = $HitSound if has_node("HitSound") else null  # Reference to Hit Sound
@onready var break_sound = $BreakSound if has_node("BreakSound") else null  # Break Sound
@export var ore_type: String = ""  # Will be set based on the scene name (e.g., "CopperNode" -> "copper_ore")
@export var collision_removal_delay: float = 0.1  # Set a default removal delay

var ore_health: int  # Ore health value

# Flag for auto-mining
var is_auto_mining: bool = false
var is_manual_mining: bool = false  # Track if the player is manually mining
var auto_mining_timer: Timer = null

# Ore dictionaries for XP, health, drop amount, etc.
var ore_health_values := {
	"copper_ore": 10,
	"silver_ore": 20,
	"gold_ore": 60,
	"rune_ore": 100,
	"dragon_ore": 200
}

var xp_on_hit := {
	"copper_ore": 2,
	"silver_ore": 5,
	"gold_ore": 6,
	"rune_ore": 7,
	"dragon_ore": 10
}

var xp_on_break := {
	"copper_ore": 10,
	"silver_ore": 15,
	"gold_ore": 25,
	"rune_ore": 50,
	"dragon_ore": 100
}

var drop_amounts := {
	"copper_ore": [4, 5],  # Drops between 1-2
	"silver_ore": [3, 4],  # Drops between 1-3
	"gold_ore": [3, 4],    # Drops between 2-4
	"rune_ore": [2, 5],    # Drops between 2-5
	"dragon_ore": [1, 7]   # Drops between 3-6
}

# Pickaxe damage values based on equipped pickaxe
var pickaxe_damage_values := {
	"Hollowed Pickaxe": 1,
	"Copper Infused Pickaxe": 2,
	"Silver Infused Pickaxe": 3,
	"Gold Infused Pickaxe": 4,
	"Rune Infused Pickaxe": 5,
	"Dragon Pickaxe": 10
}

# Called when the ore is ready (initialize ore health and load texture)
func _ready():
	# Initialize the timer for auto-mining
	auto_mining_timer = Timer.new()  # Create a new timer
	auto_mining_timer.wait_time = 1  # Set the timer interval to 1 second (adjustable)
	auto_mining_timer.connect("timeout", Callable(self, "_on_auto_mining_tick"))  # Connect the timer to the tick function
	add_child(auto_mining_timer)  # Add the timer as a child node of this ore node
	auto_mining_timer.stop()  # Initially stop the timer until auto-mining starts

	# Derive ore type from the node's scene name (e.g., CopperNode -> copper_ore)
	ore_type = self.ore_type.to_lower() + "_ore"

	# Set ore health based on the ore type
	ore_health = ore_health_values.get(ore_type, 10)  # Default health is 10

	# Ensure the sprite texture is loaded correctly
	var texture_path = "res://assets/OreNodes/" + ore_type + ".png"
	if FileAccess.file_exists(texture_path):
		sprite.texture = load(texture_path)
		print("✅ Loaded texture for:", ore_type)
	else:
		sprite.texture = load("res://assets/OreNodes/copper_node.png")  # Fallback to default texture if not found

	# Connect hitbox area detection
	if hitbox:
		hitbox.connect("area_entered", Callable(self, "_on_hit"))

	# Ensure visibility if ore is still present
	sprite.visible = true

func _process(delta):
	if is_auto_mining and player.position.distance_to(global_position) < 50:  # Distance threshold
		start_auto_mining()

# Detect when the player swings the pickaxe and hits the ore
func _on_hit(area):
	if area == $PickaxeSprite/hitbox:  # Ensure the pickaxe hitbox is the one being hit
		print("⛏️ Ore detected during swing:", ore_type)  # Debug output

		# Start auto-mining if the auto-mine flag is true
		if is_auto_mining:
			print("⛏️ Starting auto-mining for ore:", ore_type)  # Debug output
			start_auto_mining()  # Start auto-mining


# Start the mining process
func start_mining():
	var damage = 0  # Default mining damage if no pickaxe is equipped

	# Get the equipped pickaxe and its stats
	var pickaxe_path = player_stats.get_equipped_item("pickaxe")
	if pickaxe_path != "":
		var pickaxe = load(pickaxe_path)
		if pickaxe and pickaxe is ItemResource:
			damage = pickaxe.stats_resource.stats.get("mining_power", 1)  # Default to 1 if not found

	# Apply auto-mining damage
	ore_health = max(ore_health - damage, 0)
	print("Ore health after auto-mining:", ore_health)

	# Apply XP gain for hitting the ore
	var xp_gain = xp_on_hit.get(ore_type, 0)
	player_stats.gain_xp("mining", xp_gain)
	print("📌 Gained", xp_gain, "XP for breaking the ore.")

	# Update the stats panel after gaining XP
	player_stats.update_skill_levels()
	GlobalState.save_all_data()  # Save the game state immediately after leveling up

	# Check if ore is destroyed and break it, otherwise continue mining
	if ore_health <= 0:
		break_ore()
	else:
		print("Ore health is not yet 0, continue mining.")

	# Play hit sound
	if hit_sound:
		hit_sound.play()

func detect_ore_in_swing_area(hitbox: Area2D) -> Node:
	var collided_areas = hitbox.get_overlapping_areas()

	for area in collided_areas:
		if area.is_in_group("ores"):  # Ensure it's an ore group
			print("Detected ore:", area.name)  # Debug output
			return area  # Return the OreNode itself, not the ore data
	return null


# Start the auto-mining process (called by Player.gd)
func start_auto_mining():
	if is_auto_mining:
		return  # Don't start multiple mining processes

	print("⛏️ Starting auto-mining on", ore_type)  # Debug output
	is_auto_mining = true
	auto_mining_timer.start()  # Start the timer for auto-mining


func stop_auto_mining():
	if not is_auto_mining:
		return  # Auto-mining is already stopped

	print("⛏️ Stopping auto-mining on", ore_type)  # Debug output
	is_auto_mining = false
	auto_mining_timer.stop()  # Stop the auto-mining timer

func _on_auto_mining_tick():
	if ore_health <= 0:
		print("🪨 Ore health is 0, breaking ore.")  # Debug output
		break_ore()  # Break the ore
		stop_auto_mining()  # Stop the timer once the ore is broken
		return
		
		# Apply XP gain for hitting the ore
	var xp_gain = xp_on_hit.get(ore_type, 0)
	player_stats.gain_xp("mining", xp_gain)
	print("📌 Gained", xp_gain, "XP for breaking the ore.")


	# Retrieve the equipped pickaxe from PlayerStats
	var pickaxe_path = player_stats.get_equipped_item("pickaxe")

	if pickaxe_path != "":  # Ensure a pickaxe is equipped
		var pickaxe = load(pickaxe_path)
		if pickaxe and pickaxe is ItemResource:
			print("⛏️ Mining with pickaxe:", pickaxe.item_name)  # Debug output

			# Directly access the StatsResource from the pickaxe
			var stats_resource = pickaxe.stats_resource  # Direct reference to the StatsResource
			if stats_resource:
				# Get mining power from the StatsResource
				var damage = stats_resource.stats.get("mining_power", 1)  # Default to 1 if mining power is not found
				ore_health -= damage
				print("Ore health after auto-mining:", ore_health)  # Debug output
			else:
				print("❌ Missing StatsResource for pickaxe!")  # Debug output

	if hit_sound:
		hit_sound.play()


func break_ore():
	if ore_health > 0:
		return

	print("🪨 Ore destroyed!")

	var drop_range = drop_amounts.get(ore_type, [1, 1])
	var drop_amount = randi_range(drop_range[0], drop_range[1])

	var ore_item_path = "res://assets/Ores/" + ore_type.strip_edges() + ".tres"
	var ore_resource = load(ore_item_path) as ItemResource

	if ore_resource:
		player_stats.add_item_to_inventory(ore_resource, drop_amount)
		print("📌 Added", drop_amount, ore_resource.item_name, "to inventory")
	else:
		print("❌ Could not load ore item from:", ore_item_path)
		# Optionally handle the failure

	var xp_gain = xp_on_break.get(ore_type, 0)
	player_stats.gain_xp("mining", xp_gain)
	print("📌 Gained", xp_gain, "XP for breaking the ore.")
	player_stats.update_skill_levels()
	GlobalState.save_all_data()  # Save the game state immediately
	
	var collision_shape = get_node("CollisionShape2D")
	if collision_shape:
		collision_shape.disabled = true
		print("✅ Collision shape disabled during break")

	sprite.visible = false

	if break_sound and is_inside_tree():
		break_sound.play()
		await break_sound.finished

	GlobalState.save_mined_ore(global_position, ore_type, self)
	queue_free()

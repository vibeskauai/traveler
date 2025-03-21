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
	"silver_ore": 3,
	"gold_ore": 5,
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
	# Derive ore type from the node's scene name (e.g., CopperNode -> copper_ore)
	# Get the correct ore type from the scene's defined ore type (e.g., copper, silver, etc.)
	ore_type = self.ore_type.to_lower() + "_ore"

	# Set ore health based on the ore type
	ore_health = ore_health_values.get(ore_type, 10)  # Default health is 10

	# Ensure the sprite texture is loaded correctly
	var texture_path = "res://assets/OreNodes/" + ore_type + ".png"

	# Load texture for the ore sprite
	if FileAccess.file_exists(texture_path):
		sprite.texture = load(texture_path)
		print("✅ Loaded texture for:", ore_type)
	else:
		sprite.texture = load("res://assets/OreNodes/CopperNode.png")  # Fallback to default texture if not found

	# Connect hitbox area detection
	if hitbox:
		hitbox.connect("area_entered", Callable(self, "_on_hit"))

	# Setup auto-mining timer
	auto_mining_timer = Timer.new()
	auto_mining_timer.wait_time = 1  # Time in seconds between auto-mining actions
	auto_mining_timer.connect("timeout", Callable(self, "_on_auto_mining_tick"))
	add_child(auto_mining_timer)  # Add timer to the scene
	auto_mining_timer.stop()  # Initially stop the timer

	# Ensure visibility if ore is still present
	sprite.visible = true

# Detect when the player swings the pickaxe and hits the ore
func _on_hit(area):
	# Check if the area is the pickaxe hitbox
	if area == $PickaxeSprite/hitbox:  # Assuming the pickaxe hitbox is a child of PickaxeSprite
		print("⛏️ Ore detected during swing:", ore_type)
		
		# Continue with mining logic...
		if Input.is_action_just_pressed("mine_ore"):
			is_manual_mining = true
			print("🔨 Manual mining started!")
		else:
			is_manual_mining = false  # Auto-mining
			print("⛏️ Auto mining started!")

		# Start mining
		start_mining()

# Start the mining process
func start_mining():
	var damage = 0  # Default mining damage if no pickaxe is equipped

	# Get the equipped pickaxe and its stats
	var pickaxe_path = player_stats.get_equipped_item("pickaxe")
	if pickaxe_path != "":
		var pickaxe = load(pickaxe_path)
		if pickaxe and pickaxe is ItemResource:
			damage = pickaxe.stats_resource.stats.get("mining_power", 1)  # Default to 1 if not found

	# Apply manual mining bonus if active
	if is_manual_mining:
		damage *= 1.25  # Increase damage by 25% for manual mining

	# Reduce ore health, ensuring it doesn't go below 0
	ore_health = max(ore_health - damage, 0)
	print("Ore health after mining:", ore_health)

	# Apply XP gain for hitting the ore
	var xp_gain = xp_on_hit.get(ore_type, 0)
	player_stats.gain_xp("mining", xp_gain)
	print("📌 Gained", xp_gain, "XP for hitting the ore.")

	# Check if ore is destroyed and break it, otherwise continue mining
	if ore_health <= 0:
		break_ore()
	else:
		print("Ore health is not yet 0, continue mining.")

	# Play hit sound
	if hit_sound:
		hit_sound.play()


# Start the auto-mining process (e.g., when player swings pickaxe)
func start_auto_mining():
	if is_auto_mining:
		return  # Don't start multiple mining processes

	print("⛏️ Starting auto-mining on", ore_type)
	is_auto_mining = true
	auto_mining_timer.start()  # Start the timer for auto-mining

# Stop the auto-mining process (e.g., when ore is destroyed or player moves away)
func stop_auto_mining():
	if not is_auto_mining:
		return  # Auto-mining is already stopped

	print("⛏️ Stopping auto-mining on", ore_type)
	is_auto_mining = false
	auto_mining_timer.stop()  # Stop the auto-mining timer

# This function is called every time the auto-mining timer times out
func _on_auto_mining_tick():
	if ore_health <= 0:
		break_ore()
		stop_auto_mining()
		return

	var damage = 1
	var pickaxe_path = player_stats.get_equipped_item("pickaxe")

	if pickaxe_path != "":
		var pickaxe = load(pickaxe_path)
		if pickaxe and pickaxe is ItemResource:
			damage = pickaxe.stats.get("mining_power", 1)

	ore_health -= damage
	print("Ore health after auto-mining:", ore_health)

	if hit_sound:
		hit_sound.play()

# Mining logic: Reduce ore health and check if the ore should break
func mine_ore(pickaxe: ItemResource, player: Node):
	if not pickaxe or not (pickaxe is ItemResource):
		print("❌ Invalid or missing pickaxe during mining.")
		return

	var damage = pickaxe.stats.get("mining_power", 1)
	ore_health -= damage
	print("Ore health after mining:", ore_health)

	if ore_health <= 0:
		break_ore()
		print("🪨 Ore destroyed!")
	else:
		print("Ore health is not yet 0, continue mining.")

	if hit_sound:
		hit_sound.play()


func break_ore():
	if ore_health > 0:
		return

	print("🪨 Ore destroyed!")

	var drop_range = drop_amounts.get(ore_type, [1, 1])
	var drop_amount = randi_range(drop_range[0], drop_range[1])

# Remove the "Ore" suffix if it's already included in ore_type (e.g., "CopperOre")
	var ore_item_path = "res://assets/items/" + ore_type.capitalize() + ".tres"
	var ore_resource = load(ore_item_path) as ItemResource

	if ore_resource:
		player_stats.add_item_to_inventory(ore_resource, drop_amount)
		print("📌 Added", drop_amount, ore_resource.item_name, "to inventory")
	else:
		print("❌ Could not load ore item from:", ore_item_path)

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

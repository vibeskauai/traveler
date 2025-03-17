extends CharacterBody2D

@onready var label = $Label3D
@onready var area = $Area2D

var player_in_range = false
var typing_speed = 0.02
var typing = false
var dialogue_index = 0
var pickaxe_given = false

# First-time dialogue (only shown if the player never got the pickaxe)
var first_time_dialogue = [
	"Hello, Traveler!",
	"Before you are the Molten Mines...",
	"Within its depths, you will find the Volcanic Heart which I know you seek...",
	"But first! You need the right equipment!",
	"Luckily for you, I happen to have a spare pickaxe lying around.",
	"But this is no ordinary pickaxe, it is a Hollowed Pickaxe.",
	"If you collect enough ore, I will infused it to increase its mining damage!",
	"You need 100 Copper Ore for your first pickaxe upgrade!"
]

# Dynamic dialogue after receiving the pickaxe
var repeat_dialogue = [ "Come back when you have enough ore for your next upgrade!" ]

# Required ore for each pickaxe upgrade
var pickaxe_upgrades = {
	"hollowed_pickaxe": { "next": "copper_infused_pickaxe", "ore": "copper_ore", "amount": 100, "damage": 2 },
	"copper_infused_pickaxe": { "next": "silver_infused_pickaxe", "ore": "silver_ore", "amount": 100, "damage": 3 },
	"silver_infused_pickaxe": { "next": "gold_infused_pickaxe", "ore": "gold_ore", "amount": 100, "damage": 4 },
	"gold_infused_pickaxe": { "next": "rune_infused_pickaxe", "ore": "rune_ore", "amount": 100, "damage": 5 },
	"rune_infused_pickaxe": { "next": "dragon_infused_pickaxe", "ore": "dragon_ore", "amount": 100, "damage": 7 }
}

func _ready():
	label.hide()  # Hide the label initially
	
	# Ensure PlayerStats is loaded before checking
	await get_tree().process_frame  # Wait for the frame to ensure PlayerStats is initialized

	# Load saved data from GlobalState
	var save_data = GlobalState.load_game_data()

	# Check if the player has spoken to Durmil before from PlayerStats
	PlayerStats.has_spoken_to_durmil = save_data.get("has_spoken_to_durmil", false)

	# Automatically give the pickaxe if the player hasn't already received it
	if not PlayerStats.has_spoken_to_durmil and !pickaxe_given:
		give_hollowed_pickaxe()

func give_hollowed_pickaxe():
	# Create a new Item instance (Hollowed Pickaxe)
	var hollowed_pickaxe = preload("res://Assets/Pickaxes/hollowed_pickaxe.png").instance()  # Preload and instance the Item resource
	hollowed_pickaxe.name = "Hollowed Pickaxe"
	hollowed_pickaxe.type = "weapon"
	hollowed_pickaxe.damage = 10  # Example damage value (remove durability)

	# Add the pickaxe to the inventory
	PlayerStats.add_item_to_inventory(hollowed_pickaxe.name, 1)  # Add the pickaxe with quantity 1
	PlayerStats.equip_item("Hollowed Pickaxe")  # Equip it
	pickaxe_given = true  # Mark that the pickaxe has been given

	# Update player stats to reflect the new item
	PlayerStats.sync_player_stats()

	# Dialogue after receiving the pickaxe
	label.text = first_time_dialogue.join("\n")
	# Mark that the player has spoken to Durmil
	PlayerStats.has_spoken_to_durmil = true
	GlobalState.save_game_data()  # Save game state

func _on_area_2d_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true
		label.show()

func _on_area_2d_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		label.hide()  # Only hide text when player leaves

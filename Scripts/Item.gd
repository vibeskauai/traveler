extends Resource

# Define the properties for each item (e.g., name, type, damage, etc.)
@export var name: String
@export var type: String  # "weapon", "armor", "tool", etc.
@export var description: String
@export var icon: Texture  # Optional: Icon for the item
@export var damage: int  # Damage for weapons, etc.

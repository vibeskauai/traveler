extends Resource
class_name ItemResource

@export var item_name: String = "Unnamed Item"
@export var item_type: String = "resource"  # tools, weapon, armor, resource, etc.
@export var description: String = ""
@export var icon: Texture2D
@export var can_equip: bool = false  # ores are not equippable
@export var equip_slot: String = ""  # unused for ores
@export var stats_resource: StatsResource = null  # not needed for ores
@export var upgrade_path: Array[String] = []  # unused for ores

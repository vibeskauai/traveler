extends Resource
class_name ItemResource

@export var item_name: String = "Unnamed Item"
@export var item_type: String = "misc"  # weapon, armor, tool, resource
@export var description: String = ""
@export var icon: Texture2D
@export var can_equip: bool = true
@export var equip_slot: String = ""  # weapon, tool, head, chest, etc.
@export var stats_resource: StatsResource  # ✅ use this instead of a Dictionary
@export var upgrade_path: Array[String] = []

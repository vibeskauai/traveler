# ResourceManager.gd
extends Node

func load_item_resource(item_name: String) -> ItemResource:
	var item_path = "res://assets/Ores/" + item_name.capitalize() + ".tres"
	var item_resource = load(item_path) as ItemResource
	if not item_resource:
		printerr("❌ Could not load item resource:", item_name)
	return item_resource

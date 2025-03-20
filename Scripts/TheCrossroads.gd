# TheCrossroads.gd

extends Node

@onready var the_crossroads = get_node("/root/TheCrossroads")  # Assuming TheCrossroads is part of the scene tree

func _ready():
	# Call GlobalState to remove mined ores from the scene
	GlobalState.remove_mined_ores(the_crossroads)

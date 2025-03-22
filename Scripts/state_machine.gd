extends Node

@export var starting_state: NodePath
var current_state: Node = null

func _ready():
	if starting_state != null:
		current_state = get_node(starting_state)
		current_state.enter()

func change_state(new_state: Node) -> void:
	if current_state:
		current_state.exit()
	current_state = new_state
	current_state.enter()

func _process(delta):
	if current_state:
		current_state.process(delta)

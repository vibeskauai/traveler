extends Area2D

# Signal to communicate when the NPC is clicked
signal npc_clicked

func _ready():
	# Connect the input event to the _on_NPC_input function
	connect("input_event", Callable(self, "_on_NPC_input"))

# Detect mouse clicks using custom input action "click_left"
func _on_NPC_input(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		# Check if the custom input action "click_left" is pressed (left mouse button)
		if Input.is_action_just_pressed("click_left"):
			emit_signal("npc_clicked")  # Emit the signal when clicked
			print("this worked")  # Print message only on click, not hover

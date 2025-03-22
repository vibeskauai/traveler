extends Node

@onready var animation_player = $AnimationPlayer

func enter() -> void:
	# Determine the swing direction based on player velocity or facing direction
	if Input.is_action_pressed("walk_up"):
		animation_player.play("swing_up")  # Ensure you have a "swing_up" animation set up
	elif Input.is_action_pressed("walk_down"):
		animation_player.play("swing_down")  # Ensure you have a "swing_down" animation set up
	elif Input.is_action_pressed("walk_left"):
		animation_player.play("swing_left")  # Ensure you have a "swing_left" animation set up
	elif Input.is_action_pressed("walk_right"):
		animation_player.play("swing_right")  # Ensure you have a "swing_right" animation set up

func process(delta) -> void:
	# If the swing animation finishes, return to idle state
	if animation_player.is_playing() == false:
		get_parent().change_state(get_node("IdleState"))

extends Node

@onready var animation_player = $AnimationPlayer

func enter() -> void:
	animation_player.play("walk")  # Ensure you have a "walk" animation set up

func process(delta) -> void:
	if not (Input.is_action_pressed("walk_right") or Input.is_action_pressed("walk_left") or Input.is_action_pressed("walk_up") or Input.is_action_pressed("walk_down")):
		get_parent().change_state(get_node("IdleState"))

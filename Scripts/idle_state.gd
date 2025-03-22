extends Node

@onready var animation_player = $AnimationPlayer

func enter() -> void:
	animation_player.play("idle")  # Ensure you have an "idle" animation set up

func process(delta) -> void:
	if Input.is_action_pressed("walk_right") or Input.is_action_pressed("walk_left") or Input.is_action_pressed("walk_up") or Input.is_action_pressed("walk_down"):
		get_parent().change_state(get_node("WalkingState"))

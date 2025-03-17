extends Camera2D

@export var offset_distance: float = 0  # How far ahead the camera should look based on facing direction
@export var use_facing_offset: bool = true    # Whether to apply facing offset

func _ready() -> void:
	# Immediately set the camera's global position to match the player's.
	# Since the camera is a child of the player, set its local position to zero.
	global_position = get_parent().global_position

	# Temporarily disable smoothing so the camera snaps to the correct position on load.
	position_smoothing_enabled = false

	# Make this camera current.
	make_current()
	
	# If using facing offset, set the offset based on the player's last facing direction.
	if use_facing_offset and GlobalState:
		offset = GlobalState.last_facing_direction * offset_distance

	# Wait one frame, then re-enable smoothing.
	await get_tree().create_timer(0.01).timeout
	position_smoothing_enabled = true
	position_smoothing_speed = 5.0

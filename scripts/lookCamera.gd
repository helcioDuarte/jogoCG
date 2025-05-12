extends Camera3D

@onready var player = get_node($"../../player".get_path())
const follow_speed = 0.1

func _process(delta):
	if current and is_instance_valid(player):
		look_at(player.global_position, Vector3.UP)

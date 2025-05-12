extends Camera3D

@onready var player = get_node($"../../player".get_path())
const follow_speed = 0.1

func _process(delta):
	if current and is_instance_valid(player):
		var new_pos = Vector3(player.global_position.x - 5, player.global_position.y + 2, global_position.z)
		global_position = global_position.lerp(new_pos, follow_speed)

extends Camera3D

@onready var player = get_node($"../../player".get_path())
@onready var pos0 = Vector3(global_position.x, global_position.y, global_position.z)
const follow_speed = 0.1
var activated = true
var new_pos = null
func set_camera():
	global_position = Vector3(player.global_position.x - 5, player.global_position.y + 2, global_position.z)
	activated = true
	current = true

func _process(delta):
	if current and is_instance_valid(player):
		new_pos = Vector3(player.global_position.x - 5, player.global_position.y + 2, global_position.z)
		global_position = global_position.lerp(new_pos, follow_speed)

	# reset camera position when not used so trigger doesn't get messed up
	if !current and activated:
		global_position = pos0
		activated = false

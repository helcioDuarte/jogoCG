extends Camera3D

@onready var player = get_node($"../../player".get_path())
@onready var pos0 = Vector3(global_position.x, global_position.y, global_position.z)
@export var inverted = false

const follow_speed = 0.1
var activated = true
var new_pos = null
func set_camera():
	if inverted:
		global_position = Vector3(player.global_position.x + 3, player.global_position.y + 1, global_position.z)
	else:
		global_position = Vector3(player.global_position.x - 3, player.global_position.y + 1, global_position.z)
	activated = true
	current = true

func _process(delta):
	if current and is_instance_valid(player):
		if inverted:
			new_pos = Vector3(player.global_position.x + 3, player.global_position.y + 1, global_position.z)
		else:
			new_pos = Vector3(player.global_position.x - 3, player.global_position.y + 1, global_position.z)
		if abs(pos0.z - player.global_position.z) > 4:
			new_pos.z = player.global_position.z
		else:
			new_pos.z = pos0.z
		if Input.is_action_pressed("sprint"):
			global_position = global_position.lerp(new_pos, follow_speed * 2)
		else:
			global_position = global_position.lerp(new_pos, follow_speed)
	# reset camera position when not used so trigger doesn't get messed up
	if !current and activated:
		global_position = pos0
		activated = false

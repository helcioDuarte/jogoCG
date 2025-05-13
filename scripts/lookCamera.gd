extends Camera3D

@onready var player = get_node($"../../player".get_path())
@onready var r0 = Vector3(global_rotation.x, global_rotation.y, global_rotation.z)
const follow_speed = 0.1
var activated = true

func set_camera():
	look_at(player.global_position, Vector3.UP)
	activated = true
	current = true

func _process(delta):
	if current and is_instance_valid(player):
		look_at(player.global_position, Vector3.UP)

	if !current and activated:
		global_rotation = r0

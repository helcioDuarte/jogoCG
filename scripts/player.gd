extends CharacterBody3D

@export var speed = 5.0
@onready var camera_node = get_viewport().get_camera_3d()

func _physics_process(_delta):
	var input_dir = Input.get_vector("left", "right", "front", "back")
	var direction = Vector3.ZERO

	if camera_node:
		var camera_basis = camera_node.global_transform.basis

		var camera_forward = camera_basis.z
		var camera_right = camera_basis.x

		camera_forward.y = 0
		camera_right.y = 0
		camera_forward = camera_forward.normalized()
		camera_right = camera_right.normalized()

		direction = (camera_right * input_dir.x) + (camera_forward * input_dir.y)
		direction = direction.normalized()

	if direction:
		velocity = direction * speed
	else:
		velocity = Vector3.ZERO

	move_and_slide()

	if velocity.length() > 0.1:
		look_at(global_position + velocity, Vector3.UP)

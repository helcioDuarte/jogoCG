extends CharacterBody3D

@export var speed = 5.0

@onready var camera_node = get_viewport().get_camera_3d() 

var current_input_dir = Vector2.ZERO
var last_frame_input_dir = Vector2.ZERO
var active_world_movement_direction = Vector3.ZERO

var _camera_was_just_switched = false

func switch_camera():
	camera_node = get_viewport().get_camera_3d()
	_camera_was_just_switched = true

func _physics_process(delta: float):
	current_input_dir = Input.get_vector("left", "right", "front", "back")

	var new_calculated_direction_from_camera = Vector3.ZERO

	if current_input_dir == Vector2.ZERO:
		active_world_movement_direction = Vector3.ZERO
	elif current_input_dir != last_frame_input_dir:
		if is_instance_valid(camera_node):
			var camera_basis = camera_node.global_transform.basis
			var cam_forward = camera_basis.z
			var cam_right = camera_basis.x

			cam_forward.y = 0
			cam_right.y = 0

			if cam_forward.length_squared() > 0.0001:
				cam_forward = cam_forward.normalized()
			else:
				cam_forward = Vector3.ZERO
			
			if cam_right.length_squared() > 0.0001:
				cam_right = cam_right.normalized()
			else:
				cam_right = Vector3.ZERO

			new_calculated_direction_from_camera = (cam_right * current_input_dir.x) + (cam_forward * current_input_dir.y)
			
			if new_calculated_direction_from_camera.length_squared() > 0.0001:
				active_world_movement_direction = new_calculated_direction_from_camera.normalized()
			else:
				active_world_movement_direction = Vector3.ZERO 
		else:
			active_world_movement_direction = Vector3.ZERO
	elif _camera_was_just_switched:
		pass 

	_camera_was_just_switched = false
	last_frame_input_dir = current_input_dir

	# Aplica o movimento
	if active_world_movement_direction != Vector3.ZERO:
		velocity = active_world_movement_direction * speed
	else:
		# Sem direção ativa, para imediatamente.
		velocity = Vector3.ZERO # <--- PARADA IMEDIATA

	move_and_slide()

	if velocity.length_squared() > 0.01:
		var look_target_offset = velocity.normalized()
		if look_target_offset != Vector3.ZERO : 
			look_at(global_position + look_target_offset, Vector3.UP)

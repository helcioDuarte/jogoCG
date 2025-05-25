extends CharacterBody3D

@export var speed = 5.0
@export var sprint_multiplier = 2.0

@onready var camera_node = get_viewport().get_camera_3d() 
@onready var inventory = $InventoryPanel

var current_input_dir = Vector2.ZERO
var last_frame_input_dir = Vector2.ZERO
var active_world_movement_direction = Vector3.ZERO

var _camera_was_just_switched = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	inventory.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func handle_inventory_input():
	if Input.is_action_just_pressed("open_inventory"):
		if !is_instance_valid(inventory):
			return
		
		inventory.visible = not inventory.visible
		get_tree().paused = inventory.visible
		
		if inventory.visible:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
		get_viewport().set_input_as_handled() # Evita que o input seja processado por outros nós

func switch_camera():
	camera_node = get_viewport().get_camera_3d()
	_camera_was_just_switched = true

func _physics_process(delta: float):
	handle_inventory_input()
	if inventory.visible:
		return
	
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
	
	var current_speed = speed * sprint_multiplier if Input.is_action_pressed("sprint") else speed
	# Aplica o movimento
	if active_world_movement_direction != Vector3.ZERO:
		velocity = active_world_movement_direction * current_speed
	else:
		# Sem direção ativa, para imediatamente.
		velocity = Vector3.ZERO # <--- PARADA IMEDIATA

	move_and_slide()

	if velocity.length_squared() > 0.01:
		var look_target_offset = velocity.normalized()
		if look_target_offset != Vector3.ZERO : 
			look_at(global_position + look_target_offset, Vector3.UP)

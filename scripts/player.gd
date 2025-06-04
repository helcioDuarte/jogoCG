extends CharacterBody3D

@export var speed = 5.0
@export var sprint_multiplier = 2.0
@export var impact_spark_system_path: NodePath

@onready var sparks_fx = get_node_or_null(impact_spark_system_path) if impact_spark_system_path else null
@onready var camera_node = get_viewport().get_camera_3d() 
@onready var inventory = $InventoryPanel
@onready var animations = $model
@onready var pipe = $model/Armature/Skeleton3D/BoneAttachment3D/pipe

var current_input_dir = Vector2.ZERO
var last_frame_input_dir = Vector2.ZERO
var active_world_movement_direction = Vector3.ZERO

var _camera_was_just_switched = false

func hit_pipe():
	if not is_instance_valid(pipe) or not is_instance_valid(sparks_fx):
		if not is_instance_valid(pipe):
			print("Referência do 'pipe' não é válida em hit_pipe()")
		if not is_instance_valid(sparks_fx):
			print("Sistema de faíscas não configurado ou não encontrado.")
		return
	var attack_reach = 2 

	var ray_origin = pipe.global_transform.origin 
	
	var forward_direction = -camera_node.global_transform.basis.z.normalized() if is_instance_valid(camera_node) else -global_transform.basis.z.normalized()
	var ray_end = ray_origin + forward_direction * attack_reach

	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)

	query.collision_mask = 1 


	var result = space_state.intersect_ray(query)

	if result:
		print("Pipe atingiu: ", result.collider.name if result.collider else "algo")
		var impact_position = result.position
		var impact_normal = result.normal
		var hit_collider = result.collider if result.collider else null 


		if hit_collider is MeshInstance3D:
			var mesh_instance = hit_collider as MeshInstance3D
		sparks_fx.emit_sparks(impact_position, impact_normal)
	else:
		print("Pipe não atingiu nada.")
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

	if Input.is_action_pressed("sprint") and velocity.length() != 0:
		animations.changeWalkRun("run")
	else:
		animations.changeWalkRun("walk")
		
	if Input.is_action_just_pressed("hit"):
		animations.changeWalkSlash()
		hit_pipe()
	animations.animateMovement(velocity, speed)
	move_and_slide()
	
	
	if velocity.length_squared() > 0.01:
		var target_dir = velocity.normalized()
		var current_dir = -global_transform.basis.z.normalized()
		var angle_diff = rad_to_deg(acos(clamp(current_dir.dot(target_dir), -1.0, 1.0)))

		if angle_diff < 150.0:
			var lerped_dir = current_dir.lerp(target_dir, delta * 10.0).normalized()
			look_at(global_position + lerped_dir, Vector3.UP)
		else:
			look_at(global_position + target_dir, Vector3.UP)

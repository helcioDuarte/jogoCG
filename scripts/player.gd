extends CharacterBody3D

@export var speed = 13.0
@export var sprint_multiplier = 2.0
@export var pipe_damage = 10

@onready var camera_node = get_viewport().get_camera_3d()
@onready var inventory = $InventoryPanel
@onready var animations = $model
@onready var pipe = $model/Armature/Skeleton3D/BoneAttachment3D/pipe
@onready var step_up_ray = $StepUpRay
@onready var other_ray = $OtherRay
@onready var boneco_andando = $BonecoAndando

var current_input_dir = Vector2.ZERO
var last_frame_input_dir = Vector2.ZERO
var active_world_movement_direction = Vector3.ZERO

var _camera_was_just_switched = false
var is_playing_walk_sound = false

func move():
	if velocity.length() > 0 and step_up_ray.is_colliding() and not other_ray.is_colliding():
		global_position.y += step_up_ray.get_collision_point().y
	move_and_slide()

func hit_pipe():
	var attack_reach = 2.0
	var ray_origin = pipe.global_transform.origin
	var forward_direction = - camera_node.global_transform.basis.z.normalized() if is_instance_valid(camera_node) else -global_transform.basis.z.normalized()
	var ray_end = ray_origin + forward_direction * attack_reach

	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	
	query.collision_mask = 1 | 2

	var result = space_state.intersect_ray(query)

	if result:
		var hit_collider = result.collider
		var impact_position = result.position
		var impact_normal = result.normal
		
		if hit_collider and hit_collider.has_method("take_damage"):
			hit_collider.call("take_damage", pipe_damage)

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	inventory.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func handle_inventory_input():
	if Input.is_action_just_pressed("open_inventory"):
		if !is_instance_valid(inventory):
			return
		
		inventory.pause()
		inventory.visible = not inventory.visible
		get_tree().paused = inventory.visible
		if inventory.visible:
			stop_sound()
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
		get_viewport().set_input_as_handled()

func switch_camera():
	camera_node = get_viewport().get_camera_3d()
	$spark_particle.switch_camera()
	_camera_was_just_switched = true

func _physics_process(delta: float):
	handle_inventory_input()
	if inventory.current_health <= 0:
		animations.die()
		return
	if get_tree().paused:
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
	if active_world_movement_direction != Vector3.ZERO:
		velocity = active_world_movement_direction * current_speed
	else:
		velocity = Vector3.ZERO
	
	if velocity.length() != 0:
		play_sound()
		if Input.is_action_pressed("sprint"):
			animations.changeWalkRun("run")
		else:
			animations.changeWalkRun("walk")
	else:
		stop_sound()
		animations.changeWalkRun("idle")
		
	if Input.is_action_just_pressed("hit"):
		if animations.animationFinished("Slash"):
			animations.changeWalkSlash()
			speed = 0
			hit_pipe()
			await get_tree().create_timer(1.3).timeout
			speed = 3
	animations.animateMovement(velocity, speed)
	if $go_up_trigger.should_step_up():
		global_position.y += 0.1
	elif not is_on_floor():
		global_position.y -= 0.05
	move_and_slide()
	
	if velocity.length_squared() > 0.01:
		var target_dir = velocity.normalized()
		var current_dir = - global_transform.basis.z.normalized()
		var angle_diff = rad_to_deg(acos(clamp(current_dir.dot(target_dir), -1.0, 1.0)))

		if angle_diff < 150.0:
			var lerped_dir = current_dir.lerp(target_dir, delta * 10.0).normalized()
			look_at(global_position + lerped_dir, Vector3.UP)
		else:
			look_at(global_position + target_dir, Vector3.UP)

func play_sound():
	if not is_playing_walk_sound:
		boneco_andando.play()
		is_playing_walk_sound = true

func stop_sound():
	if is_playing_walk_sound:
		boneco_andando.stop()
		is_playing_walk_sound = false

func save_state() -> Dictionary:
	return {
		"position": global_position,
		"rotation": rotation
	}

func load_state(data: Dictionary):
	if get_tree().current_scene.name == "overworld":
		if data.has("position"):
			if data["position"] is String:
				data["position"] = data["position"].replace("(", "").replace(")", "").split(", ")
				global_position.x = float(data["position"][0])
				global_position.y = float(data["position"][1])
				global_position.z = float(data["position"][2])
			else:
				global_position = data["position"]
		if data.has("rotation"):
			if data["rotation"] is String:
				data["rotation"] = data["rotation"].replace("(", "").replace(")", "").split(", ")
				rotation.x = float(data["rotation"][0])
				rotation.y = float(data["rotation"][1])
				rotation.z = float(data["rotation"][2])
			else:
				rotation = data["rotation"]

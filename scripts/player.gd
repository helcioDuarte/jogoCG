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
@onready var boneco_correndo = $BonecoCorrendo
@onready var cano_audio = $CanoBatendo
@onready var errar_audio = $"WeaponSwingInAir,Whoosh3(soundFx)"
@onready var facada = $Esfaquear
@onready var inv_audio = $BloqueadoEffect
@onready var pistola_tiro = $PistolEffect


var nearby_placeholder = null
var current_input_dir = Vector2.ZERO
var last_frame_input_dir = Vector2.ZERO
var active_world_movement_direction = Vector3.ZERO
var is_sprinting: bool = false # <- to usando pra saber se o helsio ta correndo
var _camera_was_just_switched = false
var is_playing_walk_sound = false

func move():
	if velocity.length() > 0 and step_up_ray.is_colliding() and not other_ray.is_colliding():
		global_position.y += step_up_ray.get_collision_point().y
	move_and_slide()

func hit_pipe():
	var enemy_to_target = $Area3D.get_enemy() # Pega o inimigo mais próximo
	var attack_range = 2 # Distância máxima para o ataque corpo a corpo
	
	# Vira para o inimigo se houver um
	if enemy_to_target:
		var target_position_flat = enemy_to_target.global_transform.origin
		target_position_flat.y = global_position.y
		look_at(target_position_flat, Vector3.UP)
  
		# Verifica se o inimigo está dentro do alcance de ataque
		if global_position.distance_to(enemy_to_target.global_transform.origin) <= attack_range:
			if enemy_to_target.has_method("take_damage"):
				await get_tree().create_timer(0.77).timeout
				cano_audio.play()
				enemy_to_target.call("take_damage", 10)
	else:
		await get_tree().create_timer(0.73).timeout
		errar_audio.play()
				
func hit_knife():
	var enemy_to_target = $Area3D.get_enemy() # Pega o inimigo mais próximo
	var attack_range = 1.5 # Distância máxima para o ataque corpo a corpo
	
	# Vira para o inimigo se houver um
	if enemy_to_target:
		var target_position_flat = enemy_to_target.global_transform.origin
		target_position_flat.y = global_position.y
		look_at(target_position_flat, Vector3.UP)
  
		# Verifica se o inimigo está dentro do alcance de ataque
		if global_position.distance_to(enemy_to_target.global_transform.origin) <= attack_range:
			if enemy_to_target.has_method("take_damage"):
				await get_tree().create_timer(0.9).timeout
				facada.play()
				enemy_to_target.call("take_damage", 15)
	else:
		await get_tree().create_timer(0.85).timeout
		errar_audio.play()
				
func hit_revolver():
	var enemy_to_target = $Area3D.get_enemy() # Pega o inimigo mais próximo
	var attack_range = 15 # Distância máxima para o ataque corpo a corpo
	
	# Vira para o inimigo se houver um
	if enemy_to_target:
		var target_position_flat = enemy_to_target.global_transform.origin
		target_position_flat.y = global_position.y
		look_at(target_position_flat, Vector3.UP)

		# Verifica se o inimigo está dentro do alcance de ataque
		if global_position.distance_to(enemy_to_target.global_transform.origin) <= attack_range:
			if enemy_to_target.has_method("take_damage"):
				await get_tree().create_timer(0.24).timeout
				pistola_tiro.play()
				enemy_to_target.call("take_damage", 30)

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	inventory.visible = false
	print("--- DIAGNÓSTICO DO JOGADOR ---")
	print("Eu estou na Camada de Colisão: ", self.collision_layer)
	print("-----------------------------")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	

func handle_inventory_input():
	if Input.is_action_just_pressed("open_inventory"):
		if !is_instance_valid(inventory):
			return
		
		inv_audio.play()
		inventory.pause()
		inventory.visible = not inventory.visible
		get_tree().paused = inventory.visible
		if inventory.visible:
			stop_all_sounds()
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
	weapon_handler()
	if Input.is_action_just_pressed("interact"):
		if nearby_placeholder and nearby_placeholder.current_bear_id != "":
			print("Pegando um urso do lugar.")
			var picked_up_bear_id = nearby_placeholder.pickup_bear()
			if picked_up_bear_id:
				inventory.add_item_to_inventory(picked_up_bear_id, 1)
			get_viewport().set_input_as_handled()
			return
	
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
	
	is_sprinting = Input.is_action_pressed("sprint") and velocity.length() > 0
	var current_speed = speed * sprint_multiplier if is_sprinting else speed
	# Aplica o movimento
	if active_world_movement_direction != Vector3.ZERO:
		velocity = active_world_movement_direction * current_speed
	else:
		velocity = Vector3.ZERO
	
	if velocity.length() != 0:
		if is_sprinting:
			play_run_sound()
			animations.changeWalkRun("run")
		else:
			play_walk_sound()
			animations.changeWalkRun("walk")
	else:
		stop_all_sounds()
		animations.changeWalkRun("idle")
	
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

func play_walk_sound():
	if not boneco_andando.playing:
		boneco_correndo.stop()
		boneco_andando.play()

func play_run_sound():
	if not boneco_correndo.playing:
		boneco_andando.stop()
		boneco_correndo.play()

func stop_all_sounds():
	if boneco_andando.playing:
		boneco_andando.stop()
	if boneco_correndo.playing:
		boneco_correndo.stop()

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

func register_placeholder(placeholder):
	nearby_placeholder = placeholder
	print("Perto de um lugar de urso.")

func unregister_placeholder(placeholder):
	if nearby_placeholder == placeholder:
		nearby_placeholder = null
		print("Longe de um lugar de urso.")

func use_puzzle_item(item_id: String):
	if nearby_placeholder and nearby_placeholder.current_bear_id == "":
		print("Colocando ", item_id)
		nearby_placeholder.place_bear(item_id)
		inventory.remove_item_from_inventory(item_id, 1)
	else:
		print("Nenhum lugar vago para colocar o urso.")
		
		
func weapon_handler():
	if inventory.get_equipped_item() == "cano":
		$model/Armature/Skeleton3D/BoneAttachment3D/pipe.visible = true
		if Input.is_action_just_pressed("hit") and animations.animationFinished("Slash"):
			animations.changeWalkSlash()
			speed = 0
			hit_pipe()
			await get_tree().create_timer(1.4).timeout
			speed = 3
	else: 
		$model/Armature/Skeleton3D/BoneAttachment3D/pipe.visible = false
		
	if inventory.get_equipped_item() == "faca":
		$model/Armature/Skeleton3D/BoneAttachment3D/knife.visible = true
		if Input.is_action_just_pressed("hit") and animations.animationFinished("Stab"):
			animations.changeWalkStab()
			speed = 0
			hit_knife()
			await get_tree().create_timer(2.06).timeout
			speed = 3
	else: 
		$model/Armature/Skeleton3D/BoneAttachment3D/knife.visible = false
		
	if inventory.get_equipped_item() == "revolver":
		$model/Armature/Skeleton3D/BoneAttachment3D/revolver.visible = true
		if Input.is_action_just_pressed("hit") and animations.animationFinished("Revolver"):
			animations.changeWalkRevolver()
			speed = 0
			hit_revolver()
			await get_tree().create_timer(1.2).timeout
			speed = 3
	else: 
		$model/Armature/Skeleton3D/BoneAttachment3D/revolver.visible = false


func pewpewpew():
	pistola_tiro.play()

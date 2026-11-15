extends CharacterBody3D

@export var speed = 3.0
@export var sprint_multiplier = 2.0
@export var pipe_damage = 10

@onready var camera_node = get_viewport().get_camera_3d()
@onready var inventory = $InventoryPanel
@onready var animations = $model
@onready var pipe = $model/Armature/Skeleton3D/BoneAttachment3D/pipe
@onready var boneco_andando = $BonecoAndando
@onready var boneco_correndo = $BonecoCorrendo
@onready var cano_audio = $CanoBatendo
@onready var errar_audio = $"WeaponSwingInAir,Whoosh3(soundFx)"
@onready var facada = $Esfaquear
@onready var inv_audio = $BloqueadoEffect
@onready var pistola_tiro = $PistolEffect
@onready var mortetela = $Morte

var nearby_placeholder = null
var current_input_dir = Vector2.ZERO
var last_frame_input_dir = Vector2.ZERO
var active_world_movement_direction = Vector3.ZERO
var is_sprinting: bool = false # <- to usando pra saber se o helsio ta correndo
var _camera_was_just_switched = false
var is_playing_walk_sound = false
var can_move = true
var is_dead: bool = false

func hit_pipe():
	var enemy_to_target = $Area3D.get_enemy() # Pega o inimigo mais próximo
	var attack_range = 2 # Distância máxima para o ataque corpo a corpo
	
	# Vira para o inimigo se houver um
	if is_instance_valid(enemy_to_target):
		var target_position_flat = enemy_to_target.global_transform.origin
		target_position_flat.y = global_position.y
		if global_position.distance_squared_to(target_position_flat) > 0.0001:
			look_at(target_position_flat, Vector3.UP)
  
		# Verifica se o inimigo está dentro do alcance de ataque
		if global_position.distance_to(enemy_to_target.global_transform.origin) <= attack_range:
			if enemy_to_target.has_method("take_damage"):
				await get_tree().create_timer(0.77).timeout
				if not is_instance_valid(enemy_to_target):
					return
				cano_audio.play()
				enemy_to_target.call("take_damage", 10)
				return
	await get_tree().create_timer(0.73).timeout
	errar_audio.play()
				
func hit_knife():
	var enemy_to_target = $Area3D.get_enemy() # Pega o inimigo mais próximo
	var attack_range = 1.5 # Distância máxima para o ataque corpo a corpo
	
	# Vira para o inimigo se houver um
	if is_instance_valid(enemy_to_target):
		var target_position_flat = enemy_to_target.global_transform.origin
		target_position_flat.y = global_position.y
		if global_position.distance_squared_to(target_position_flat) > 0.0001:
			look_at(target_position_flat, Vector3.UP)
  
		# Verifica se o inimigo está dentro do alcance de ataque
		if global_position.distance_to(enemy_to_target.global_transform.origin) <= attack_range:
			if enemy_to_target.has_method("take_damage"):
				await get_tree().create_timer(0.9).timeout
				if not is_instance_valid(enemy_to_target):
					return
				facada.play()
				enemy_to_target.call("take_damage", 15)
				return
	await get_tree().create_timer(0.85).timeout
	errar_audio.play()
				
func hit_revolver():
	var enemy_to_target = $Area3D.get_enemy() # Pega o inimigo mais próximo
	var attack_range = 15 # Distância máxima para o ataque corpo a corpo
	
	# Vira para o inimigo se houver um
	if is_instance_valid(enemy_to_target):
		var target_position_flat = enemy_to_target.global_transform.origin
		target_position_flat.y = global_position.y
		if global_position.distance_squared_to(target_position_flat) > 0.0001:
			look_at(target_position_flat, Vector3.UP)

		# Verifica se o inimigo está dentro do alcance de ataque
		if global_position.distance_to(enemy_to_target.global_transform.origin) <= attack_range:
			if enemy_to_target.has_method("take_damage"):
				await get_tree().create_timer(0.24).timeout
				pistola_tiro.play()
				if not is_instance_valid(enemy_to_target):
					return
				enemy_to_target.call("take_damage", 30)
				return
	await get_tree().create_timer(0.24).timeout
	pistola_tiro.play()

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	inventory.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	

func handle_inventory_input():
	if is_dead or not is_instance_valid(inventory):
		return
	var toggle_pressed = Input.is_action_just_pressed("open_inventory")
	var cancel_pressed = inventory.visible and Input.is_action_just_pressed("ui_cancel")
	if toggle_pressed or cancel_pressed:
		if get_tree().paused and not inventory.visible:
			return
		inv_audio.play()
		inventory.pause()
		inventory.visible = not inventory.visible
		get_tree().paused = inventory.visible
		if inventory.visible:
			stop_all_sounds()
			inventory.update_ui_elements()
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			if inventory.is_combine_mode:
				inventory.cancel_combination_mode()
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
		get_viewport().set_input_as_handled()

func switch_camera():
	camera_node = get_viewport().get_camera_3d()
	$spark_particle.switch_camera()
	_camera_was_just_switched = true

func _calculate_camera_movement_direction(input_dir: Vector2) -> Vector3:
	if not is_instance_valid(camera_node):
		return Vector3.ZERO
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

	var new_calculated_direction_from_camera = (cam_right * input_dir.x) + (cam_forward * input_dir.y)
	if new_calculated_direction_from_camera.length_squared() > 0.0001:
		return new_calculated_direction_from_camera.normalized()
	return Vector3.ZERO

func _physics_process(delta: float):
	if inventory.current_health <= 0 and not is_dead:
		die()
		return
	handle_inventory_input()
	if is_dead:
		return
	if get_tree().paused:
		return
	weapon_handler()
	if Input.is_action_just_pressed("interact"):
		if nearby_placeholder and nearby_placeholder.current_bear_id != "":
			print("Pegando um urso do lugar.")
			var picked_up_bear_id = nearby_placeholder.pickup_bear()
			if picked_up_bear_id:
				inventory.add_item_to_inventory(picked_up_bear_id, 1)
			get_viewport().set_input_as_handled()
			return
	
	if not is_instance_valid(camera_node):
		camera_node = get_viewport().get_camera_3d()
		if is_instance_valid(camera_node):
			_camera_was_just_switched = true

	current_input_dir = Input.get_vector("left", "right", "front", "back")

	if current_input_dir == Vector2.ZERO:
		active_world_movement_direction = Vector3.ZERO
	elif current_input_dir != last_frame_input_dir:
		active_world_movement_direction = _calculate_camera_movement_direction(current_input_dir)
	elif _camera_was_just_switched:
		# Keep the current world movement direction across fixed-camera cuts (God of War style)
		# until the player changes or releases their input; only initialize if still zero.
		if active_world_movement_direction == Vector3.ZERO:
			active_world_movement_direction = _calculate_camera_movement_direction(current_input_dir)

	_camera_was_just_switched = false
	last_frame_input_dir = current_input_dir
	
	is_sprinting = Input.is_action_pressed("sprint") and velocity.length() > 0
	var current_speed = speed * sprint_multiplier if is_sprinting else speed
	# Aplica o movimento
	if active_world_movement_direction != Vector3.ZERO and can_move:
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
		global_position.y += 6.0 * delta
	elif not is_on_floor():
		global_position.y -= 3.0 * delta
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

func _parse_vector3(val, fallback: Vector3) -> Vector3:
	if val is Vector3:
		return val
	if val is Array or val is PackedStringArray or val is PackedFloat32Array or val is PackedFloat64Array:
		if val.size() >= 3:
			return Vector3(float(val[0]), float(val[1]), float(val[2]))
	if val is String:
		var parts = val.replace("(", "").replace(")", "").split(",")
		if parts.size() >= 3:
			return Vector3(float(parts[0].strip_edges()), float(parts[1].strip_edges()), float(parts[2].strip_edges()))
	return fallback

func load_state(data: Dictionary):
	if data.has("position"):
		global_position = _parse_vector3(data["position"], global_position)
	if data.has("rotation"):
		rotation = _parse_vector3(data["rotation"], rotation)

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
			can_move = false # <-- Mude aqui
			hit_pipe()
			await get_tree().create_timer(1.4).timeout
			if not is_dead:
				can_move = true # <-- E aqui
	else:
		$model/Armature/Skeleton3D/BoneAttachment3D/pipe.visible = false

	# Faça o mesmo para as outras armas (faca e revólver)
	if inventory.get_equipped_item() == "faca":
		$model/Armature/Skeleton3D/BoneAttachment3D/knife.visible = true
		if Input.is_action_just_pressed("hit") and animations.animationFinished("Stab"):
			animations.changeWalkStab()
			can_move = false # <-- Mude aqui
			hit_knife()
			await get_tree().create_timer(2.06).timeout
			if not is_dead:
				can_move = true # <-- E aqui
	else:
		$model/Armature/Skeleton3D/BoneAttachment3D/knife.visible = false

	if inventory.get_equipped_item() == "revolver":
		$model/Armature/Skeleton3D/BoneAttachment3D/revolver.visible = true
		if Input.is_action_just_pressed("hit") and animations.animationFinished("Revolver"):
			var rev = inventory.get_inventory_item_by_id("revolver")
			if rev.is_empty() or int(rev.get("current_ammo", 0)) <= 0:
				inv_audio.play()
				return
			rev["current_ammo"] = int(rev["current_ammo"]) - 1
			inventory.update_ui_elements()
			animations.changeWalkRevolver()
			can_move = false # <-- Mude aqui
			hit_revolver()
			await get_tree().create_timer(1.2).timeout
			if not is_dead:
				can_move = true # <-- E aqui
	else:
		$model/Armature/Skeleton3D/BoneAttachment3D/revolver.visible = false

func die():
	is_dead = true
	can_move = false # Impede que o player deslize enquanto morre
	stop_all_sounds()
	animations.die()
	
	# Aguarda o tempo da animação antes de continuar
	await get_tree().create_timer(2.633).timeout 
	
	# Mostra a tela de morte APÓS a animação
	if is_instance_valid(mortetela):
		mortetela.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	await get_tree().create_timer(2.0).timeout
	get_tree().paused = false
	if FileAccess.file_exists("user://save.dat") and TransitionManager.load_game():
		TransitionManager.start(TransitionManager.get_saved_scene())
	else:
		TransitionManager.start("res://scenes/menu.tscn")

func pewpewpew():
	pistola_tiro.play()

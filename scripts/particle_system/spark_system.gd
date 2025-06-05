extends Node3D

@export_group("Emissão")
@export var emission_active: bool = true
@export var emission_shape_extents: Vector3 = Vector3(25, 25, 25)
@export var particles_per_emission_min: int = 50
@export var particles_per_emission_max: int = 100
@export var emission_interval: float = 0.1

@export_group("Vida e Movimento")
@export var lifetime_min: float = 1.5
@export var lifetime_max: float = 3.0
@export var initial_drift_speed_min: float = 0.1
@export var initial_drift_speed_max: float = 0.5
@export var spread_degrees: float = 90.0
@export var constant_force: Vector3 = Vector3(0, -1.5, 0)

@export_group("Aparência")
@export var particle_size_min: float = 0.5
@export var particle_size_max: float = 1.0
@export var spark_base_color: Color = Color(1.0, 0.6, 0.1, 1.0)
@export var alpha_curve: Curve
@export var size_curve: Curve

@export_group("Turbulência")
@export var turbulence_enabled: bool = true
@export var turbulence_strength: float = 0.2
@export var turbulence_frequency: float = 0.8
@export var turbulence_speed: float = 0.4

@onready var multimesh_instance: MultiMeshInstance3D = $MultiMeshInstance3D
var multimesh_res: MultiMesh
var camera: Camera3D

var particles_data_array: Array[ParticleDataSpark] = []
var available_particle_indices: Array[int] = []

var emission_timer: Timer
var noise_generator: FastNoiseLite
var rng: RandomNumberGenerator

class ParticleDataSpark:
	var active: bool = false
	var position: Vector3 = Vector3.ZERO
	var velocity: Vector3 = Vector3.ZERO
	var age: float = 0.0
	var lifetime: float = 1.0
	var base_random_size: float = 1.0
	var current_alpha: float = 1.0
	var current_display_size: float = 1.0

func _ready():
	if not multimesh_instance:
		printerr(self.name, ": Nó filho MultiMeshInstance3D (com nome 'MultiMeshInstance3D') não encontrado!")
		set_process(false)
		return

	multimesh_res = multimesh_instance.multimesh
	if not multimesh_res:
		printerr(self.name, ": Recurso MultiMesh não encontrado em '", multimesh_instance.name, "'")
		set_process(false)
		return

	if not multimesh_res.mesh is QuadMesh:
		printerr(self.name, ": O Mesh do MultiMesh DEVE ser um QuadMesh.")
		set_process(false)
		return

	rng = RandomNumberGenerator.new()
	rng.randomize()

	particles_data_array.resize(multimesh_res.instance_count)
	for i in range(multimesh_res.instance_count):
		particles_data_array[i] = ParticleDataSpark.new()
		available_particle_indices.push_back(i)
		multimesh_res.set_instance_transform(i, Transform3D().scaled(Vector3.ZERO))
		multimesh_res.set_instance_color(i, Color(0,0,0,0))

	noise_generator = FastNoiseLite.new()
	noise_generator.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise_generator.frequency = turbulence_frequency
	noise_generator.fractal_octaves = 2

	emission_timer = Timer.new()
	emission_timer.wait_time = emission_interval
	emission_timer.one_shot = false
	emission_timer.timeout.connect(_on_emission_timer_timeout)
	add_child(emission_timer)
	if emission_active:
		emission_timer.start()

	set_process(true)

func _process(delta: float):
	if not multimesh_res: return

	if not camera:
		camera = get_viewport().get_camera_3d()
	if not camera:
		return

	var cam_global_basis_ortho = camera.global_transform.basis.orthonormalized()
	var mmi_global_basis_ortho = multimesh_instance.global_transform.basis.orthonormalized()
	var mmi_global_basis_ortho_inverse = mmi_global_basis_ortho.inverse()

	for i in range(multimesh_res.instance_count):
		var p_data: ParticleDataSpark = particles_data_array[i]
		if not p_data.active:
			continue

		p_data.age += delta
		if p_data.age >= p_data.lifetime:
			p_data.active = false
			available_particle_indices.push_back(i)
			multimesh_res.set_instance_color(i, Color(0,0,0,0))
			multimesh_res.set_instance_transform(i, Transform3D().scaled(Vector3.ZERO))
			continue

		var life_ratio: float = p_data.age / p_data.lifetime

		if turbulence_enabled:
			var noise_time_component = p_data.age * turbulence_speed
			var p_pos_scaled = p_data.position * turbulence_frequency

			var turbulence_offset = Vector3(
				noise_generator.get_noise_3d(p_pos_scaled.x, p_pos_scaled.y, noise_time_component),
				noise_generator.get_noise_3d(p_pos_scaled.y, p_pos_scaled.z, noise_time_component + 10.0),
				noise_generator.get_noise_3d(p_pos_scaled.z, p_pos_scaled.x, noise_time_component + 20.0)
			).normalized() * turbulence_strength
			p_data.velocity += turbulence_offset * delta

		p_data.velocity += constant_force * delta
		p_data.position += p_data.velocity * delta

		if alpha_curve:
			p_data.current_alpha = alpha_curve.sample_baked(life_ratio)
		else:
			if life_ratio < 0.1: p_data.current_alpha = life_ratio / 0.1
			elif life_ratio > 0.9: p_data.current_alpha = (1.0 - life_ratio) / 0.1
			else: p_data.current_alpha = 1.0

		var final_color = spark_base_color
		final_color.a *= clampf(p_data.current_alpha, 0.0, 1.0)
		multimesh_res.set_instance_color(i, final_color)

		if size_curve:
			p_data.current_display_size = p_data.base_random_size * size_curve.sample_baked(life_ratio)
		else:
			p_data.current_display_size = p_data.base_random_size

		var scale_vector = Vector3(p_data.current_display_size, p_data.current_display_size, 1.0)

		var local_particle_position = multimesh_instance.to_local(p_data.position)

		var desired_particle_basis_world = cam_global_basis_ortho.scaled(scale_vector)
		var required_particle_basis_local = mmi_global_basis_ortho_inverse * desired_particle_basis_world

		var billboard_transform = Transform3D(required_particle_basis_local, local_particle_position)
		multimesh_res.set_instance_transform(i, billboard_transform)


func _on_emission_timer_timeout():
	if not emission_active:
		return
	emit_batch()

func emit_batch():
	if not multimesh_res or not rng: return

	var num_to_emit = particles_per_emission_min
	if particles_per_emission_max > particles_per_emission_min:
		num_to_emit = rng.randi_range(particles_per_emission_min, particles_per_emission_max)
	if num_to_emit <= 0 && particles_per_emission_min > 0 : num_to_emit = particles_per_emission_min

	var emitter_center_pos = global_transform.origin

	for _k in range(num_to_emit):
		if available_particle_indices.is_empty():
			break

		var particle_idx: int = available_particle_indices.pop_front()
		var p_data: ParticleDataSpark = particles_data_array[particle_idx] # Renomeado

		p_data.active = true
		p_data.age = 0.0

		p_data.lifetime = lifetime_min
		if lifetime_max > lifetime_min: p_data.lifetime = rng.randf_range(lifetime_min, lifetime_max)
		if p_data.lifetime <= 0: p_data.lifetime = 0.1

		p_data.base_random_size = particle_size_min
		if particle_size_max > particle_size_min: p_data.base_random_size = rng.randf_range(particle_size_min, particle_size_max)
		if p_data.base_random_size <= 0: p_data.base_random_size = 0.01

		var random_offset = Vector3(
			rng.randf_range(-emission_shape_extents.x, emission_shape_extents.x),
			rng.randf_range(-emission_shape_extents.y, emission_shape_extents.y),
			rng.randf_range(-emission_shape_extents.z, emission_shape_extents.z)
		)
		p_data.position = emitter_center_pos + random_offset

		var random_yaw = rng.randf_range(-PI, PI)
		var half_spread_rad = deg_to_rad(spread_degrees * 0.5)
		var random_pitch = rng.randf_range(-half_spread_rad, half_spread_rad)

		var initial_direction = Vector3.DOWN.rotated(Vector3.UP, random_yaw).rotated(Vector3.RIGHT, random_pitch)

		var speed = initial_drift_speed_min
		if initial_drift_speed_max > initial_drift_speed_min: speed = rng.randf_range(initial_drift_speed_min, initial_drift_speed_max)

		p_data.velocity = initial_direction.normalized() * speed

		p_data.current_alpha = 0.0
		p_data.current_display_size = p_data.base_random_size

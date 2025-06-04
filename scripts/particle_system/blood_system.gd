extends Node3D

@export var ground_collision_mask: int = 1
@export var pnumber_min: int = 5
@export var pnumber_max: int = 15
@export var particle_lifetime_min: float = 0.5
@export var particle_lifetime_max: float = 1.5
@export var initial_spurt_speed_min: float = 1.0
@export var initial_spurt_speed_max: float = 2.0
@export var spread_angle_deg: float = 22.5
@export var gravity: Vector3 = Vector3(0, -9.8, 0)
@export var emission_rate_hz: float = 0.5
@export var stretch_factor_max: float = 1.25
@export var stretch_factor_min: float = 0.32

@onready var multimesh_node: MultiMeshInstance3D = $MultiMeshInstance3D
@onready var multimesh_res: MultiMesh = multimesh_node.multimesh if multimesh_node else null
@onready var emission_timer: Timer = $Timer

var particles_data: Array[ParticleData] = []
var particle_pool_indices: Array[int] = []

class ParticleData:
	var active: bool = false
	var position: Vector3 = Vector3.ZERO
	var velocity: Vector3 = Vector3.ZERO
	var age: float = 0.0
	var lifetime: float = 1.0
	var current_alpha: float = 1.0

func _ready():
	if not multimesh_node:
		printerr(self.name, ": Child node MultiMeshInstance3D not found!")
		set_process(false)
		return
	if not multimesh_res:
		printerr(self.name, ": MultiMesh resource not found in ", multimesh_node.name)
		set_process(false)
		return
	if not emission_timer:
		printerr(self.name, ": Child node Timer not found!")
		set_process(false)
		return

	particles_data.resize(multimesh_res.instance_count)
	for i in range(multimesh_res.instance_count):
		particles_data[i] = ParticleData.new()
		particle_pool_indices.push_back(i)
		multimesh_res.set_instance_color(i, Color(1,1,1,0))
		multimesh_res.set_instance_transform(i, Transform3D().scaled(Vector3.ZERO))

	if emission_rate_hz > 0:
		emission_timer.wait_time = 1.0 / emission_rate_hz
	else:
		emission_timer.wait_time = 1000
	emission_timer.timeout.connect(_on_emission_timer_timeout)
	if emission_timer.autostart:
		emission_timer.start()

func _on_emission_timer_timeout():
	var emit_position = global_transform.origin
	var base_emit_direction = global_transform.basis.z.normalized()
	emit_particles(emit_position, base_emit_direction)

func emit_particles(origin_position: Vector3, base_direction: Vector3):
	if not multimesh_res: return

	var num_to_emit = randi_range(pnumber_min, pnumber_max)
	
	for _i in range(num_to_emit):
		if particle_pool_indices.is_empty():
			break

		var particle_index: int = particle_pool_indices.pop_front()
		var p_data: ParticleData = particles_data[particle_index]

		p_data.active = true
		p_data.age = 0.0
		p_data.lifetime = randf_range(particle_lifetime_min, particle_lifetime_max)
		p_data.position = origin_position
		
		var random_basis = Basis().rotated(Vector3.UP, randf_range(-PI, PI)).rotated(Vector3.RIGHT, randf_range(0, deg_to_rad(spread_angle_deg)))
		var random_direction = (base_direction * random_basis).normalized()
		
		var spurt_speed = randf_range(initial_spurt_speed_min, initial_spurt_speed_max)
		p_data.velocity = random_direction * spurt_speed
		p_data.current_alpha = 1.0

func _process(delta: float):
	if not multimesh_res or not multimesh_node: return

	for i in range(multimesh_res.instance_count):
		var p_data: ParticleData = particles_data[i]
		if not p_data.active:
			continue

		p_data.age += delta
		if p_data.age >= p_data.lifetime:
			p_data.active = false
			particle_pool_indices.push_back(i)
			multimesh_res.set_instance_color(i, Color(1,1,1,0))
			multimesh_res.set_instance_transform(i, Transform3D().scaled(Vector3.ZERO))
			continue

		p_data.velocity += gravity * delta
		p_data.position += p_data.velocity * delta
		
		var t = p_data.age / p_data.lifetime
		p_data.current_alpha = clampf(1.0 - t, 0.0, 1.0) 
		
		var instance_color_with_alpha = Color(1, 1, 1, p_data.current_alpha)
		
		var current_stretch = lerp(1.0, stretch_factor_max, t)
		var current_thin = lerp(1.0, stretch_factor_min, t)

		var scale_vector = Vector3(current_thin, current_stretch, current_thin)

		var new_basis: Basis
		var particle_velocity_dir = p_data.velocity
		
		if particle_velocity_dir.length_squared() > 0.001:
			var y_axis = particle_velocity_dir.normalized()
			var x_axis: Vector3

			if abs(y_axis.dot(Vector3.UP)) < 0.99:
				x_axis = Vector3.UP.cross(y_axis).normalized()
			else:
				x_axis = Vector3.RIGHT.cross(y_axis).normalized()
			
			if x_axis.length_squared() < 0.001:
				x_axis = y_axis.orthogonal()

			var z_axis = x_axis.cross(y_axis).normalized()
			
			new_basis = Basis(x_axis, y_axis, z_axis)
		else:
			new_basis = Basis()

		var local_position_for_instance = multimesh_node.to_local(p_data.position)
		var transform = Transform3D(new_basis.scaled(scale_vector), local_position_for_instance)

		multimesh_res.set_instance_transform(i, transform)
		multimesh_res.set_instance_color(i, instance_color_with_alpha)

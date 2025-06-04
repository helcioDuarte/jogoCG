extends Node3D

@export var particles_per_impact_min: int = 2
@export var particles_per_impact_max: int = 4
@export var particle_lifetime_min: float = 0.2
@export var particle_lifetime_max: float = 0.6
@export var initial_speed_min: float = 3.0
@export var initial_speed_max: float = 7.0
@export var spread_angle_deg: float = 90.0
@export var gravity: Vector3 = Vector3(0, -9.8, 0)
@export var color_lighten_amount_min: float = 0.3
@export var color_lighten_amount_max: float = 0.7
@export var max_stretch_factor: float = 2.0
@export var min_thin_factor: float = 0.5

@onready var multimesh_node: MultiMeshInstance3D = $MultiMeshInstance3D
@onready var multimesh_res: MultiMesh = multimesh_node.multimesh if multimesh_node else null

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
		printerr(self.name, ": Nó filho MultiMeshInstance3D não encontrado!")
		set_process(false)
		return
	if not multimesh_res:
		printerr(self.name, ": Recurso MultiMesh não encontrado em ", multimesh_node.name)
		set_process(false)
		return

	particles_data.resize(multimesh_res.instance_count)
	for i in range(multimesh_res.instance_count):
		particles_data[i] = ParticleData.new()
		particle_pool_indices.push_back(i)
		multimesh_res.set_instance_color(i, Color(0,0,0,0))
		multimesh_res.set_instance_transform(i, Transform3D().scaled(Vector3.ZERO))

func emit_sparks(impact_position: Vector3, impact_normal: Vector3):
	if not multimesh_res: return

	var num_to_emit = randi_range(particles_per_impact_min, particles_per_impact_max)
	
	for _i in range(num_to_emit):
		if particle_pool_indices.is_empty():
			break

		var particle_index: int = particle_pool_indices.pop_front()
		var p_data: ParticleData = particles_data[particle_index]

		p_data.active = true
		p_data.age = 0.0
		p_data.lifetime = randf_range(particle_lifetime_min, particle_lifetime_max)
		p_data.position = impact_position
		
		p_data.current_alpha = 1.0

		var base_dir_norm = impact_normal.normalized()
		var cone_half_angle_rad = deg_to_rad(spread_angle_deg / 2.0)
		var cos_theta = randf_range(cos(cone_half_angle_rad), 1.0)
		var sin_theta = sqrt(1.0 - cos_theta * cos_theta)
		var phi = randf_range(0, TAU)
		var local_dir_x = sin_theta * cos(phi)
		var local_dir_y = sin_theta * sin(phi)
		var local_dir_z = cos_theta
		var local_random_dir = Vector3(local_dir_x, local_dir_y, local_dir_z)
		
		var Z_axis = base_dir_norm
		var X_axis: Vector3
		if abs(Z_axis.dot(Vector3.UP)) > 0.99:
			X_axis = Vector3.FORWARD.cross(Z_axis).normalized()
			if X_axis.length_squared() < 0.001:
				X_axis = Vector3.UP.cross(Z_axis).normalized()
		else:
			X_axis = Vector3.UP.cross(Z_axis).normalized()
		var Y_axis = Z_axis.cross(X_axis).normalized()
		var particle_orientation_basis = Basis(X_axis, Y_axis, Z_axis)
		var spurt_direction = (particle_orientation_basis * local_random_dir).normalized()

		var spurt_speed = randf_range(initial_speed_min, initial_speed_max)
		p_data.velocity = spurt_direction * spurt_speed

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
			multimesh_res.set_instance_color(i, Color(0,0,0,0))
			multimesh_res.set_instance_transform(i, Transform3D().scaled(Vector3.ZERO))
			continue

		p_data.velocity += gravity * delta
		p_data.position += p_data.velocity * delta
		
		var t = p_data.age / p_data.lifetime
		p_data.current_alpha = clampf(1.0 - (t * t), 0.0, 1.0)

		var instance_final_color = Color(1, 1, 1, p_data.current_alpha)

		var current_stretch = lerp(1.0, max_stretch_factor, t)
		var current_thin = lerp(1.0, min_thin_factor, t)
		
		var scale_vector = Vector3(current_thin, current_stretch, current_thin)

		var new_basis: Basis
		var particle_velocity_dir = p_data.velocity
		
		if particle_velocity_dir.length_squared() > 0.001:
			var y_axis_particle = particle_velocity_dir.normalized()
			var x_axis_particle: Vector3
			
			if abs(y_axis_particle.dot(Vector3.UP)) < 0.99:
				x_axis_particle = Vector3.UP.cross(y_axis_particle).normalized()
			else: 
				x_axis_particle = Vector3.RIGHT.cross(y_axis_particle).normalized()
			
			if x_axis_particle.length_squared() < 0.001:
				x_axis_particle = y_axis_particle.orthogonal()

			var z_axis_particle = x_axis_particle.cross(y_axis_particle).normalized()
			
			new_basis = Basis(x_axis_particle, y_axis_particle, z_axis_particle)
			new_basis = new_basis.scaled(scale_vector)
		else:
			var initial_stretch = lerp(1.0, max_stretch_factor, 0.0)
			var initial_thin = lerp(1.0, min_thin_factor, 0.0)
			new_basis = Basis().scaled(Vector3(initial_thin, initial_stretch, initial_thin))

		var local_position_for_instance = multimesh_node.to_local(p_data.position)
		var transform = Transform3D(new_basis, local_position_for_instance)

		multimesh_res.set_instance_transform(i, transform)
		multimesh_res.set_instance_color(i, instance_final_color)

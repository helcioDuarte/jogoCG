extends Node3D

var ParticleScene = preload("res://scripts/particle_system/particles/particle.tscn")
var emission_rate = 1.0 
var _emission_accumulator = 10.0
# funcao doida do godot
func _process(delta):
	_emission_accumulator += delta * emission_rate
	while _emission_accumulator >= 1.0:
		_emission_accumulator -= 1.0
		emit_particle()

func emit_particle():
	var p = ParticleScene.instantiate()
	add_child(p)
	p.global_transform.origin = global_transform.origin
	
	var initial_velocity_y = randf_range(1.0, 2.0)
	var initial_velocity_xz_angle = randf_range(0, TAU) # esse tau aparentemente = 2*pi sla pra q
	var initial_speed_xz = randf_range(0.5, 2.0)
	
	p.velocity = Vector3(sin(initial_velocity_xz_angle) * initial_speed_xz, 
						 initial_velocity_y, 
						 cos(initial_velocity_xz_angle) * initial_speed_xz)
	p.lifetime = randf_range(1.0, 3.0)
	

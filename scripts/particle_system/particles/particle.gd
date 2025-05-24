extends Node3D

var velocity = Vector3.ZERO
var lifetime = 1.0 
var age = 0.0

func _process(delta):
	age += delta
	if age >= lifetime:
		queue_free() 
		return

	global_translate(velocity * delta)
	
	#  da pra mudar cor ou tamanho ao longo do tempo
	# var t = age / lifetime
	# $MeshInstance3D.mesh.surface_get_material(0).albedo_color = Color.WHITE.lerp(Color.BLACK, t)

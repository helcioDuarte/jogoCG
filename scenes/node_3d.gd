extends Node3D

@export var cone_height: float = 5.0
@export var cone_radius: float = 2.0
@export var cone_color: Color = Color(1, 0, 0, 0.25) # vermelho transparente

func _ready():
	# Cria Area3D
	var area = Area3D.new()
	area.name = "AreaDeVisao"
	add_child(area)

	# Cria CollisionShape3D
	var shape = CylinderShape3D.new()
	shape.radius = cone_radius
	shape.height = cone_height

	var collision = CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	collision.shape = shape
	collision.position = Vector3(0, cone_height / 2.0, 0) # centraliza o shape

	area.add_child(collision)

	# Cria visualização com MeshInstance3D simulando cone
	var mesh = CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = cone_radius
	mesh.height = cone_height
	mesh.radial_segments = 24

	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "ConeVisual"
	mesh_instance.mesh = mesh
	mesh_instance.material_override = create_transparent_material(cone_color)
	mesh_instance.position = Vector3(0, cone_height / 2.0, 0)

	area.add_child(mesh_instance)

	# Opcional: Adiciona o Area3D a um grupo
	area.add_to_group("visoes_inimigos")

func create_transparent_material(color: Color) -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.flags_transparent = true
	return material

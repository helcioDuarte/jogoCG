extends Node3D

@onready var tb_loader = $TBLoader
@onready var nav_region: NavigationRegion3D = $NavigationRegion3D

func _ready():
	await tb_loader.ready
	await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout

	var nav_mesh = NavigationMesh.new()
	nav_mesh.set_source_geometry_mode(1)
	nav_region.navigation_mesh = nav_mesh
	nav_region.bake_navigation_mesh()

	print("✅ NavigationMesh gerada a partir das colisões.")

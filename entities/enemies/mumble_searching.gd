extends CharacterBody3D

@export var cone_height: float = 15.0
@export var cone_radius: float = 5.0
@export var cone_color: Color = Color(0, 0.5, 1, 0.3)
@export var velocidade: float = 5.0
@export var tempo_para_voltar: float = 5.0

enum Estado { PATRULHANDO, PERSEGUINDO, VOLTANDO }

var estado: Estado = Estado.PATRULHANDO
var jogador: Node3D = null
var tempo_desde_perda: float = 0.0

@onready var path_follow: PathFollow3D = get_parent()
@onready var animation_player: AnimationPlayer = path_follow.get_node("AnimationPlayer")
@onready var agente: NavigationAgent3D = $NavigationAgent3D

func _ready():
	animation_player.play("AnimaçãoDoCaminho")
	_criar_area_visao()

func _physics_process(delta):
	match estado:
		Estado.PERSEGUINDO:
			_perseguir_jogador(delta)
		Estado.VOLTANDO:
			_retornar_para_path(delta)
		Estado.PATRULHANDO:
			velocity = Vector3.ZERO
			move_and_slide()

func _perseguir_jogador(delta):
	if jogador == null or not jogador.is_inside_tree():
		tempo_desde_perda += delta
		if tempo_desde_perda > tempo_para_voltar:
			estado = Estado.VOLTANDO
			agente.target_position = path_follow.global_position
			print("🔙 Voltando para patrulha")
		return  # Sai aqui se estiver esperando jogador voltar
	else:
		tempo_desde_perda = 0.0  # Reset do tempo de perda

	# Ainda vendo o jogador
	agente.target_position = jogador.global_transform.origin
	var next = agente.get_next_path_position()
	var dir = (next - global_position).normalized()
	velocity = dir * velocidade
	move_and_slide()

	var olhar = jogador.global_position
	olhar.y = global_position.y
	look_at(olhar, Vector3.UP)


func _retornar_para_path(delta):
	if agente.is_navigation_finished():
		# ✅ Reposiciona e reorienta o inimigo exatamente no ponto atual do PathFollow
		global_position = path_follow.global_position
		global_rotation = path_follow.global_rotation

		# ✅ Garante que a rotação fique alinhada com a direção do caminho
		var forward = -path_follow.global_transform.basis.z.normalized()
		look_at(path_follow.global_position + forward, Vector3.UP)

		# ✅ Volta a animar
		estado = Estado.PATRULHANDO
		animation_player.play("AnimaçãoDoCaminho")
		print("✅ Retornou à patrulha")
		return

	# Movimentação de retorno continua
	var next = agente.get_next_path_position()
	var dir = (next - global_position).normalized()
	velocity = dir * velocidade
	move_and_slide()

	var olhar = path_follow.global_position
	olhar.y = global_position.y
	look_at(olhar, Vector3.UP)


func _criar_area_visao():
	var area = Area3D.new()
	area.name = "AreaDeVisao"
	add_child(area)

	var collision = CollisionShape3D.new()
	area.add_child(collision)

	var cone_mesh = CylinderMesh.new()
	cone_mesh.top_radius = 0
	cone_mesh.bottom_radius = cone_radius
	cone_mesh.height = cone_height

	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = cone_mesh
	mesh_instance.name = "ConeVisual"

	var material = StandardMaterial3D.new()
	material.albedo_color = cone_color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.flags_transparent = true
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_instance.material_override = material

	mesh_instance.rotation_degrees = Vector3(90, 0, 0)
	mesh_instance.position = Vector3(0, cone_radius / 2, -cone_height / 2)
	area.add_child(mesh_instance)

	var shape = CylinderShape3D.new()
	shape.radius = cone_radius
	shape.height = cone_height
	collision.shape = shape
	collision.rotation_degrees = Vector3(90, 0, 0)
	collision.position = Vector3(0, cone_radius / 2, -cone_height / 2)

	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player"):
		jogador = body
		estado = Estado.PERSEGUINDO
		tempo_desde_perda = 0.0
		animation_player.stop()
		print("👀 Jogador detectado!")

func _on_body_exited(body):
	if body == jogador:
		print("🚶‍♂️ Jogador saiu da visão.")
		# Aqui só marcamos que ele saiu — a lógica do tempo fica no _perseguir_jogador
		jogador = null

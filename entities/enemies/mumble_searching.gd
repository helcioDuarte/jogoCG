extends CharacterBody3D

@export var cone_height: float = 15.0
@export var cone_radius: float = 5.0
@export var cone_color: Color = Color(0, 0.5, 1, 0.3)
@export var velocidade: float = 5.0
@export var tempo_para_voltar: float = 5.0

var jogador_detectado: bool = false
var tempo_desde_perda: float = 0.0
var jogador: Node3D = null
var perseguindo: bool = false

@onready var path_follow = get_parent() # o PathFollow3D
@onready var animation_player = path_follow.get_node("AnimationPlayer")

func _ready():
	_criar_area_visao()

func _process(delta):
	if jogador_detectado and jogador:
		perseguindo = true
		animation_player.stop()
		path_follow.set_process(false) # para a patrulha
		_perseguir_jogador(delta)
		tempo_desde_perda = 0.0
	elif perseguindo:
		tempo_desde_perda += delta
		if tempo_desde_perda >= tempo_para_voltar:
			perseguindo = false
			_voltar_para_patrulha()

func _perseguir_jogador(delta):
	var dir = (jogador.global_transform.origin - global_transform.origin).normalized()
	velocity = dir * velocidade
	move_and_slide()
	# Faz o inimigo olhar para o jogador (apenas no plano horizontal)
	var pos_alvo = jogador.global_transform.origin
	pos_alvo.y = global_transform.origin.y # mantém a altura original
	look_at(pos_alvo, Vector3.UP)


func _voltar_para_patrulha():
	animation_player.play("AnimaçãoDoCaminho")
	path_follow.set_process(true)

func _criar_area_visao():
	var area = Area3D.new()
	area.name = "AreaDeVisao"
	add_child(area)

	var collision = CollisionShape3D.new()
	area.add_child(collision)

	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "ConeVisual"
	var cone_mesh = CylinderMesh.new()
	cone_mesh.top_radius = 0
	cone_mesh.bottom_radius = cone_radius
	cone_mesh.height = cone_height
	mesh_instance.mesh = cone_mesh

	var material = StandardMaterial3D.new()
	material.albedo_color = cone_color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.flags_transparent = true
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_instance.material_override = material

	area.add_child(mesh_instance)

	var shape = CylinderShape3D.new()
	shape.radius = cone_radius
	shape.height = cone_height
	collision.shape = shape

	mesh_instance.rotation_degrees = Vector3(90, 0, 0)
	collision.rotation_degrees = Vector3(90, 0, 0)

	mesh_instance.position = Vector3(0, cone_radius / 2, -cone_height / 2)
	collision.position = Vector3(0, cone_radius / 2, -cone_height / 2)

	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player"):
		jogador_detectado = true
		jogador = body
		print("👀 Jogador detectado!")

func _on_body_exited(body):
	if body.is_in_group("player"):
		jogador_detectado = false
		print("🚶‍♂️ Jogador saiu da visão.")

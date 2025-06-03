extends CharacterBody3D

@export var cone_height: float = 15.0
@export var cone_radius: float = 5.0
@export var cone_color: Color = Color(0, 0.5, 1, 0.3) # Azul claro translúcido
@export var velocidade: float = 5.0
@export var tempo_para_voltar: float = 5.0

@export var quad_area_side_length: float = 4.0
@export var quad_area_height: float = 7.0
@export var quad_area_color: Color = Color(1, 0.8, 0.2, 0.3) # Laranja/âmbar translúcido

var cone_visual_mesh: MeshInstance3D
var quadrado_visual_mesh: MeshInstance3D
var debug_visuals_visible: bool = false

var area_visao_cone: Area3D
var area_visao_quadrada: Area3D
var todas_as_areas_de_visao: Array[Area3D] = []

enum Estado { PATRULHANDO, PERSEGUINDO, VOLTANDO }

var estado: Estado = Estado.PATRULHANDO
var jogador: Node3D
var tempo_desde_perda: float = 0.0

@onready var path_follow: PathFollow3D = get_parent()
@onready var animation_player: AnimationPlayer = path_follow.get_node("AnimationPlayer")
@onready var agente: NavigationAgent3D = $NavigationAgent3D
@onready var animation_tree: AnimationTree = $Sketchfab_Scene/AnimationTree

func _ready():
	animation_player.play("AnimaçãoDoCaminho")
	animation_tree.set("parameters/conditions/walk", true)
	animation_tree.set("parameters/conditions/idle", false)

	_criar_area_visao_cone()
	_criar_area_visao_quadrada()
	
	area_visao_cone = get_node_or_null("AreaDeVisao")
	if area_visao_cone:
		todas_as_areas_de_visao.append(area_visao_cone)
		cone_visual_mesh = area_visao_cone.get_node_or_null("ConeVisual")
		if not cone_visual_mesh: printerr("Malha 'ConeVisual' não encontrada em 'AreaDeVisao'.")
	else:
		printerr("'AreaDeVisao' (cone) não encontrada.")
		
	area_visao_quadrada = get_node_or_null("AreaDeVisaoQuadrada")
	if area_visao_quadrada:
		todas_as_areas_de_visao.append(area_visao_quadrada)
		quadrado_visual_mesh = area_visao_quadrada.get_node_or_null("VisualQuadrado")
		if not quadrado_visual_mesh: printerr("Malha 'VisualQuadrado' não encontrada em 'AreaDeVisaoQuadrada'.")
	else:
		printerr("'AreaDeVisaoQuadrada' não encontrada.")

	_atualizar_visibilidade_debug_visuals()

func _atualizar_visibilidade_debug_visuals():
	if is_instance_valid(cone_visual_mesh): cone_visual_mesh.visible = debug_visuals_visible
	if is_instance_valid(quadrado_visual_mesh): quadrado_visual_mesh.visible = debug_visuals_visible

func _alternar_visibilidade_debug_visuals():
	debug_visuals_visible = not debug_visuals_visible
	_atualizar_visibilidade_debug_visuals()
	print("Visualização de depuração: ", "ATIVADA" if debug_visuals_visible else "DESATIVADA")

func _unhandled_input(event: InputEvent):
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_F1: 
			_alternar_visibilidade_debug_visuals()

func _physics_process(delta: float):
	match estado:
		Estado.PATRULHANDO:
			animation_tree.set("parameters/conditions/walk", true)
			animation_tree.set("parameters/conditions/idle", false)
			velocity = Vector3.ZERO
			move_and_slide()
		Estado.PERSEGUINDO:
			_perseguir_jogador(delta)
		Estado.VOLTANDO:
			_retornar_para_path(delta)

func _perseguir_jogador(delta: float):
	if not is_instance_valid(jogador):
		tempo_desde_perda += delta
		animation_tree.set("parameters/conditions/walk", false)
		animation_tree.set("parameters/conditions/idle", true)
		
		velocity = Vector3.ZERO
		move_and_slide()

		if tempo_desde_perda > tempo_para_voltar:
			estado = Estado.VOLTANDO
			agente.target_position = path_follow.global_position
		return 
	
	tempo_desde_perda = 0.0
	animation_tree.set("parameters/conditions/idle", false)
	animation_tree.set("parameters/conditions/walk", true)
	
	agente.target_position = jogador.global_transform.origin
	var proximo_ponto = agente.get_next_path_position()
	var direcao = global_position.direction_to(proximo_ponto)
	velocity = direcao * velocidade
	move_and_slide()

	_suavizar_rotacao(jogador.global_transform.origin, delta)

func _reativar_path():
	var pai_atual = get_parent()
	if pai_atual and path_follow:
		pai_atual.remove_child(self)
		path_follow.add_child(self)
		self.transform = Transform3D.IDENTITY
	else:
		if not pai_atual: printerr("ERRO _reativar_path: pai_atual nulo.")
		if not path_follow: printerr("ERRO _reativar_path: path_follow nulo.")

func _suavizar_rotacao(alvo: Vector3, delta: float, velocidade_rot: float = 2.0):
	var direcao_para_alvo_xz = (alvo - global_position) * Vector3(1,0,1)
	if direcao_para_alvo_xz.length_squared() < 0.0001: return

	direcao_para_alvo_xz = direcao_para_alvo_xz.normalized()
	var angulo_alvo_y = atan2(-direcao_para_alvo_xz.x, -direcao_para_alvo_xz.z)
	rotation.y = lerp_angle(rotation.y, angulo_alvo_y, velocidade_rot * delta)

func _retornar_para_path(delta: float):
	animation_tree.set("parameters/conditions/idle", false)
	animation_tree.set("parameters/conditions/walk", true)

	if agente.is_navigation_finished():
		global_position = path_follow.global_position
		global_rotation = path_follow.global_rotation

		estado = Estado.PATRULHANDO
		_reativar_path()
		animation_player.play("AnimaçãoDoCaminho")
		return

	var proximo_ponto = agente.get_next_path_position()
	var direcao = global_position.direction_to(proximo_ponto)
	velocity = direcao * velocidade
	move_and_slide()

	if not global_position.is_equal_approx(proximo_ponto):
		_suavizar_rotacao(proximo_ponto, delta)

func _criar_area_visao_cone():
	area_visao_cone = Area3D.new()
	area_visao_cone.name = "AreaDeVisao"
	add_child(area_visao_cone)

	var collision = CollisionShape3D.new()
	area_visao_cone.add_child(collision)

	var cone_mesh_data = CylinderMesh.new()
	cone_mesh_data.top_radius = 0.0
	cone_mesh_data.bottom_radius = cone_radius
	cone_mesh_data.height = cone_height

	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = cone_mesh_data
	mesh_instance.name = "ConeVisual"

	var material_vis = StandardMaterial3D.new() # Renomeado para evitar conflito de nome
	material_vis.albedo_color = cone_color
	material_vis.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material_vis.flags_transparent = true
	material_vis.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_instance.material_override = material_vis

	mesh_instance.rotation_degrees = Vector3(90, 0, 0)
	mesh_instance.position = Vector3(0, cone_radius / 2.0, -cone_height / 2.0)
	area_visao_cone.add_child(mesh_instance)

	var shape_data = CylinderShape3D.new() # Renomeado
	shape_data.radius = cone_radius
	shape_data.height = cone_height
	collision.shape = shape_data
	collision.rotation_degrees = Vector3(90, 0, 0)
	collision.position = Vector3(0, cone_radius / 2.0, -cone_height / 2.0)

	area_visao_cone.body_entered.connect(_on_body_entered)
	area_visao_cone.body_exited.connect(_on_body_exited)

func _criar_area_visao_quadrada():
	area_visao_quadrada = Area3D.new()
	area_visao_quadrada.name = "AreaDeVisaoQuadrada"
	add_child(area_visao_quadrada)

	var collision = CollisionShape3D.new()
	area_visao_quadrada.add_child(collision)

	var box_shape_data = BoxShape3D.new() # Renomeado
	box_shape_data.size = Vector3(quad_area_side_length, quad_area_height, quad_area_side_length)
	collision.shape = box_shape_data

	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "VisualQuadrado"
	area_visao_quadrada.add_child(mesh_instance)

	var box_mesh_data = BoxMesh.new() # Renomeado
	box_mesh_data.size = box_shape_data.size
	mesh_instance.mesh = box_mesh_data

	var material_vis = StandardMaterial3D.new() # Renomeado
	material_vis.albedo_color = quad_area_color
	material_vis.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material_vis.flags_transparent = true
	material_vis.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_instance.material_override = material_vis

	area_visao_quadrada.body_entered.connect(_on_body_entered)
	area_visao_quadrada.body_exited.connect(_on_body_exited)

func _desanexar_do_path():
	if get_parent() == path_follow: # Comparação mais direta com a referência @onready
		var current_transform = global_transform
		var root_node = path_follow.get_parent()
		if root_node:
			path_follow.remove_child(self)
			root_node.add_child(self)
			global_transform = current_transform
		else:
			printerr("ERRO _desanexar_do_path: Nó raiz (pai do PathFollow3D) não encontrado.")

func _on_body_entered(body: Node3D):
	if body.is_in_group("player"):
		if estado != Estado.PERSEGUINDO:
			_desanexar_do_path()
			animation_player.stop()
			estado = Estado.PERSEGUINDO
		jogador = body
		tempo_desde_perda = 0.0

func _on_body_exited(body: Node3D):
	if body == jogador:
		call_deferred("_verificar_visibilidade_jogador_apos_saida")

func _verificar_visibilidade_jogador_apos_saida():
	if not is_instance_valid(jogador): return

	var jogador_ainda_em_alguma_area = false
	for area in todas_as_areas_de_visao:
		if is_instance_valid(area) and area.get_overlapping_bodies().has(jogador):
			jogador_ainda_em_alguma_area = true
			break
	
	if jogador_ainda_em_alguma_area:
		tempo_desde_perda = 0.0
	else:
		jogador = null

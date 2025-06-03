extends CharacterBody3D

# Configurações de Visão
@export var cone_height: float = 15.0
@export var cone_radius: float = 5.0
@export var cone_color: Color = Color(0, 0.5, 1, 0.3)

@export var quad_area_side_length: float = 4.0
@export var quad_area_height: float = 7.0
@export var quad_area_color: Color = Color(1, 0.8, 0.2, 0.3)

# Comportamento
@export var velocidade: float = 5.0
@export var tempo_para_voltar: float = 5.0

# Estados de IA
enum Estado { PATRULHANDO, PERSEGUINDO, VOLTANDO, ATACANDO }
var estado: Estado = Estado.PATRULHANDO

# Variáveis de referência
var jogador: Node3D
var tempo_desde_perda: float = 0.0
var debug_visuals_visible: bool = false

# Nós de visão e visualização
var cone_visual_mesh: MeshInstance3D
var quadrado_visual_mesh: MeshInstance3D
var ataque_visual_mesh: MeshInstance3D

var area_visao_cone: Area3D
var area_visao_quadrada: Area3D
var todas_as_areas_de_visao: Array[Area3D] = []

# Referências @onready
@onready var path_follow: PathFollow3D = get_parent()
@onready var animation_player: AnimationPlayer = path_follow.get_node("AnimationPlayer")
@onready var agente: NavigationAgent3D = $NavigationAgent3D
@onready var animation_tree: AnimationTree = $Sketchfab_Scene/AnimationTree
@onready var ataque_area: Area3D = $AttackRangeArea
@onready var ataque_shape: CollisionShape3D = ataque_area.get_node("Ataque")

# ========== INICIALIZAÇÃO ==========
func _ready():
	animation_player.play("AnimaçãoDoCaminho")
	animation_tree.set("parameters/conditions/walk", true)
	animation_tree.set("parameters/conditions/idle", false)

	_criar_area_visao_cone()
	_criar_area_visao_quadrada()

	area_visao_cone = get_node_or_null("AreaDeVisao")
	if area_visao_cone != null:
		cone_visual_mesh = area_visao_cone.get_node_or_null("ConeVisual")
		if cone_visual_mesh == null:
			printerr("Erro: ConeVisual não encontrado dentro da AreaDeVisao.")
		else:
			todas_as_areas_de_visao.append(area_visao_cone)
	else:
		printerr("Erro: AreaDeVisao não encontrada.")

	area_visao_quadrada = get_node_or_null("AreaDeVisaoQuadrada")
	if area_visao_quadrada != null:
		quadrado_visual_mesh = area_visao_quadrada.get_node_or_null("VisualQuadrado")
		if quadrado_visual_mesh == null:
			printerr("Erro: VisualQuadrado não encontrado dentro da AreaDeVisaoQuadrada.")
		else:
			todas_as_areas_de_visao.append(area_visao_quadrada)
	else:
		printerr("Erro: AreaDeVisaoQuadrada não encontrada.")

	ataque_area.body_entered.connect(_on_body_entered_atack)
	ataque_area.body_exited.connect(_on_body_exited_atack)

	_criar_visual_area_ataque()

	_atualizar_visibilidade_debug_visuals()


# ========== CICLO DE VIDA ==========
func _physics_process(delta: float):
	match estado:
		Estado.PATRULHANDO:
			_set_anim_state(false, true, false)
			velocity = Vector3.ZERO
			move_and_slide()
		Estado.PERSEGUINDO:
			_perseguir_jogador(delta)
		Estado.VOLTANDO:
			_retornar_para_path(delta)
		Estado.ATACANDO:
			_atacar_jogador(delta)

func _unhandled_input(event: InputEvent):
	if event is InputEventKey and event.pressed and not event.is_echo() and event.keycode == KEY_F1:
		_alternar_visibilidade_debug_visuals()

# ========== COMPORTAMENTOS ==========
func _perseguir_jogador(delta: float):
	if not is_instance_valid(jogador):
		tempo_desde_perda += delta
		_set_anim_state(true, false, false)
		velocity = Vector3.ZERO
		move_and_slide()

		if tempo_desde_perda > tempo_para_voltar:
			estado = Estado.VOLTANDO
			agente.target_position = path_follow.global_position
		return

	tempo_desde_perda = 0.0
	_set_anim_state(false, true, false)
	
	agente.target_position = jogador.global_transform.origin
	var proximo_ponto = agente.get_next_path_position()
	var direcao = global_position.direction_to(proximo_ponto)
	velocity = direcao * velocidade
	move_and_slide()
	_suavizar_rotacao(jogador.global_transform.origin, delta)

func _retornar_para_path(delta: float):
	_set_anim_state(false, true, false)

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
	_suavizar_rotacao(proximo_ponto, delta)

func _atacar_jogador(delta: float):
	_set_anim_state(false, false, true)

# ========== DETECÇÃO ==========
func _on_body_entered(body: Node3D):
	if body.is_in_group("player") and estado != Estado.PERSEGUINDO:
		_desanexar_do_path()
		animation_player.stop()
		estado = Estado.PERSEGUINDO
		jogador = body
		tempo_desde_perda = 0.0

func _on_body_exited(body: Node3D):
	if body == jogador:
		call_deferred("_verificar_visibilidade_jogador_apos_saida")

func _on_body_entered_atack(body: Node3D):
	if body.is_in_group("player"):
		estado = Estado.ATACANDO

func _on_body_exited_atack(body: Node3D):
	if body.is_in_group("player"):
		estado = Estado.PERSEGUINDO

func _verificar_visibilidade_jogador_apos_saida():
	if not is_instance_valid(jogador): return
	for area in todas_as_areas_de_visao:
		if area.get_overlapping_bodies().has(jogador):
			tempo_desde_perda = 0.0
			return
	jogador = null

# ========== TRANSFORMAÇÕES ==========
func _desanexar_do_path():
	if get_parent() == path_follow:
		var current_transform = global_transform
		var root_node = path_follow.get_parent()
		if root_node:
			path_follow.remove_child(self)
			root_node.add_child(self)
			global_transform = current_transform
		else:
			printerr("Erro ao desanexar: pai do PathFollow3D não encontrado.")

func _reativar_path():
	if get_parent() and path_follow:
		get_parent().remove_child(self)
		path_follow.add_child(self)
		self.transform = Transform3D.IDENTITY
	else:
		printerr("Erro ao reativar path.")

func _suavizar_rotacao(alvo: Vector3, delta: float, velocidade_rot: float = 2.0):
	var direcao = (alvo - global_position) * Vector3(1, 0, 1)
	if direcao.length_squared() < 0.0001: return
	direcao = direcao.normalized()
	var alvo_y = atan2(-direcao.x, -direcao.z)
	rotation.y = lerp_angle(rotation.y, alvo_y, velocidade_rot * delta)

# ========== VISUALIZAÇÃO ==========
func _atualizar_visibilidade_debug_visuals():
	if cone_visual_mesh != null:
		cone_visual_mesh.visible = debug_visuals_visible
	if quadrado_visual_mesh != null:
		quadrado_visual_mesh.visible = debug_visuals_visible
	if ataque_visual_mesh != null:
		ataque_visual_mesh.visible = debug_visuals_visible

func _alternar_visibilidade_debug_visuals():
	debug_visuals_visible = not debug_visuals_visible
	_atualizar_visibilidade_debug_visuals()
	print("Debug visuals:", "ATIVADOS" if debug_visuals_visible else "DESATIVADOS")

func _criar_visual_area_ataque():
	if ataque_shape == null or ataque_shape.shape == null:
		printerr("Erro: Ataque (CollisionShape3D) não encontrado ou sem shape.")
		return

	var visual = MeshInstance3D.new()
	visual.name = "AtaqueVisual"

	if ataque_shape.shape is SphereShape3D:
		var mesh = SphereMesh.new()
		mesh.radius = ataque_shape.shape.radius
		visual.mesh = mesh
	elif ataque_shape.shape is BoxShape3D:
		var mesh = BoxMesh.new()
		mesh.size = ataque_shape.shape.size
		visual.mesh = mesh
	elif ataque_shape.shape is CapsuleShape3D:
		var mesh = CapsuleMesh.new()
		mesh.radius = ataque_shape.shape.radius
		mesh.height = ataque_shape.shape.height
		visual.mesh = mesh
	elif ataque_shape.shape is CylinderShape3D:
		var mesh = CylinderMesh.new()
		mesh.top_radius = ataque_shape.shape.radius
		mesh.bottom_radius = ataque_shape.shape.radius
		mesh.height = ataque_shape.shape.height
		visual.mesh = mesh
	else:
		printerr("Tipo de shape não suportado para visualização de ataque.")
		return

	visual.transform = ataque_shape.transform

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0, 0, 0.3)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.flags_transparent = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	visual.material_override = mat

	ataque_area.add_child(visual)
	ataque_visual_mesh = visual

# ========== UTILITÁRIOS ==========
func _set_anim_state(idle := false, walk := false, attack := false):
	animation_tree.set("parameters/conditions/idle", idle)
	animation_tree.set("parameters/conditions/walk", walk)
	animation_tree.set("parameters/conditions/attack", attack)

# ========== ÁREAS DE VISÃO ==========
func _criar_area_visao_cone():
	area_visao_cone = Area3D.new()
	area_visao_cone.name = "AreaDeVisao"
	add_child(area_visao_cone)

	var collision = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = cone_radius
	shape.height = cone_height
	collision.shape = shape
	collision.rotation_degrees = Vector3(90, 0, 0)
	collision.position = Vector3(0, cone_radius / 2.0, -cone_height / 2.0)
	area_visao_cone.add_child(collision)

	var visual = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius = 0
	mesh.bottom_radius = cone_radius
	mesh.height = cone_height
	visual.mesh = mesh
	visual.name = "ConeVisual"
	visual.rotation_degrees = Vector3(90, 0, 0)
	visual.position = collision.position

	var mat = StandardMaterial3D.new()
	mat.albedo_color = cone_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.flags_transparent = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	visual.material_override = mat
	area_visao_cone.add_child(visual)

	area_visao_cone.body_entered.connect(_on_body_entered)
	area_visao_cone.body_exited.connect(_on_body_exited)

func _criar_area_visao_quadrada():
	area_visao_quadrada = Area3D.new()
	area_visao_quadrada.name = "AreaDeVisaoQuadrada"
	add_child(area_visao_quadrada)

	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(quad_area_side_length, quad_area_height, quad_area_side_length)
	collision.shape = shape
	area_visao_quadrada.add_child(collision)

	var visual = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = shape.size
	visual.mesh = mesh
	visual.name = "VisualQuadrado"

	var mat = StandardMaterial3D.new()
	mat.albedo_color = quad_area_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.flags_transparent = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	visual.material_override = mat
	area_visao_quadrada.add_child(visual)

	area_visao_quadrada.body_entered.connect(_on_body_entered)
	area_visao_quadrada.body_exited.connect(_on_body_exited)

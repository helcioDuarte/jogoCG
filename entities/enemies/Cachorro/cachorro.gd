extends CharacterBody3D

# Configurações de Visão
@export var altura_cone: float = 15.0 / 2
@export var raio_cone: float = 5.0 / 4
@export var cor_cone: Color = Color(0, 0.5, 1, 0.3)

@export var esfera_raio: float = 10.0
@export var esfera_altura: float = 7.0 / 2
@export var esfera_cor: Color = Color(1, 0.8, 0.2, 0.3)

# Comportamento
@export var velocidade: float = 2.5
#+ Velocidade com que o alvo se move no caminho durante a patrulha.
@export var velocidade_patrulha: float = 2.5
@export var tempo_para_voltar: float = 5.0
@export var dano_ataque: float = 0
@export var vida: float = 20
@export var velocidade_rot: float = 5.0

# Estados de IA
enum Estado { PATRULHANDO, PERSEGUINDO, VOLTANDO, ATACANDO }
var estado: Estado = Estado.PATRULHANDO

# Variáveis de referência
var jogador: Node3D
var tempo_desde_perda: float = 0.0
var debug_visuals_visible: bool = false

# Nós de visão e visualização
var cone_visual_mesh: MeshInstance3D
var esfera_visual_mesh: MeshInstance3D
var ataque_visual_mesh: MeshInstance3D
var area_visao_cone: Area3D
var area_visao_redonda: Area3D
var todas_as_areas_de_visao: Array[Area3D] = []

# Variaveis de comportamento
var _pode_causar_dano_neste_ciclo_anim: bool = false

# Referências @onready
#~ Arraste o nó PathFollow3D (seu "PontoNoCaminho") para esta variável no Inspetor.
@export var patrulha_alvo: PathFollow3D
#- @onready var path_follow: PathFollow3D = get_parent()
#- @onready var animation_player: AnimationPlayer = path_follow.get_node("AnimacaoDoCaminho")
@onready var agente: NavigationAgent3D = $NavigationAgent3D
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var ataque_area: Area3D = $AttackRangeArea
@onready var ataque_shape: CollisionShape3D = ataque_area.get_node("Ataque")


# ========== INICIALIZAÇÃO ==========
func _ready():
	#- animation_player.play("AnimaçãoDoCaminho")
	#+ Começa no estado de patrulha, então a animação de andar deve estar ativa.
	_set_anim_state(false, true, false)

	_criar_area_visao_cone()
	_criar_area_visao_esferica()

	todas_as_areas_de_visao.clear()

	area_visao_cone = get_node_or_null("AreaDeVisao")
	if area_visao_cone != null:
		cone_visual_mesh = area_visao_cone.get_node_or_null("ConeVisual")
		if cone_visual_mesh == null:
			printerr("Erro: ConeVisual não encontrado dentro da AreaDeVisao.")
		else:
			todas_as_areas_de_visao.append(area_visao_cone)
	else:
		printerr("Erro: AreaDeVisao não encontrada.")

	area_visao_redonda = get_node_or_null("AreaDeVisaoRedonda")
	if area_visao_redonda != null:
		esfera_visual_mesh = area_visao_redonda.get_node_or_null("VisualRedondo")
		if esfera_visual_mesh == null:
			printerr("Erro: VisualRedondo não encontrado dentro da AreaDeVisaoRedibda.")
		else:
			todas_as_areas_de_visao.append(area_visao_redonda)
	else:
		printerr("Erro: AreaDeVisaoRedonda não encontrada.")

	ataque_area.body_entered.connect(_on_body_entered_atack)
	ataque_area.body_exited.connect(_on_body_exited_atack)

	_criar_visual_area_ataque()
	_atualizar_visibilidade_debug_visuals()


# ========== CICLO DE VIDA ==========
func _physics_process(delta: float):
	match estado:
		Estado.PATRULHANDO:
			_patrulhar(delta) #~ Lógica de patrulha foi movida para uma função própria
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

#+ NOVA FUNÇÃO PARA PATRULHA
func _patrulhar(delta: float):
	_set_anim_state(false, true, false)
	
	if not is_instance_valid(patrulha_alvo):
		velocity = Vector3.ZERO
		move_and_slide()
		return

	# Move o ponto-alvo ao longo do caminho.
	patrulha_alvo.progress += velocidade_patrulha * delta

	# Pega a posição global do alvo para o agente de navegação
	agente.target_position = patrulha_alvo.global_position
	
	# Calcula a direção do inimigo até o próximo ponto do caminho gerado pelo agente.
	var proximo_ponto = agente.get_next_path_position()
	var direcao = global_position.direction_to(proximo_ponto)

	# Define a velocidade na direção do alvo.
	velocity = direcao * velocidade

	move_and_slide()
	_suavizar_rotacao_pela_velocidade(delta)


func _perseguir_jogador(delta: float):
	if not is_instance_valid(jogador):
		tempo_desde_perda += delta
		_set_anim_state(true, false, false)
		velocity = Vector3.ZERO
		move_and_slide()

		if tempo_desde_perda > tempo_para_voltar:
			estado = Estado.VOLTANDO
			#~ O alvo para voltar é a posição atual do ponto de patrulha
			agente.target_position = patrulha_alvo.global_position
		return

	tempo_desde_perda = 0.0
	_set_anim_state(false, true, false)

	agente.target_position = jogador.global_transform.origin
	var proximo_ponto = agente.get_next_path_position()
	var direcao = global_position.direction_to(proximo_ponto)
	velocity = direcao * velocidade
	move_and_slide()
	_suavizar_rotacao_pela_velocidade(delta)


func _retornar_para_path(delta: float):
	_set_anim_state(false, true, false)
	
	#~ Quando o agente de navegação termina de retornar, simplesmente muda o estado.
	if agente.is_navigation_finished():
		estado = Estado.PATRULHANDO
		return

	var proximo_ponto = agente.get_next_path_position()
	var direcao = global_position.direction_to(proximo_ponto)
	velocity = direcao * velocidade
	move_and_slide()
	_suavizar_rotacao_pela_velocidade(delta)


func _atacar_jogador(delta: float):
	# (Sua função de ataque permanece a mesma)
	_set_anim_state(false, false, true)

	if is_instance_valid(jogador):
		if global_position.distance_squared_to(jogador.global_position) > 0.01:
			var alvo_para_olhar = jogador.global_position
			alvo_para_olhar.y = global_position.y
			look_at(alvo_para_olhar, Vector3.UP)


func _iniciar_novo_ciclo_ataque():
	if estado == Estado.ATACANDO:
		_pode_causar_dano_neste_ciclo_anim = true
		
		
func _ponto_de_impacto_do_ataque():
	if estado == Estado.ATACANDO and is_instance_valid(jogador) and _pode_causar_dano_neste_ciclo_anim:
		var corpos_na_area_de_ataque = ataque_area.get_overlapping_bodies()
		if corpos_na_area_de_ataque.has(jogador):
			var painel_inventario = jogador.get_node_or_null("InventoryPanel")
			if painel_inventario and painel_inventario.has_method("take_damage"):
				painel_inventario.take_damage(dano_ataque)
			else:
				var script_path = "Nenhum"
				if jogador.get_script():
					script_path = jogador.get_script().resource_path
				printerr("ERRO: O nó ", jogador.name, " (Tipo: ", jogador.get_class() , ",  Script: ", script_path, " não possui o método 'take_damage'.")

			_pode_causar_dano_neste_ciclo_anim = false
		
# ========== DETECÇÃO ==========
func _on_body_entered(body: Node3D):
	if body.is_in_group("player"):
		#~ Não precisa mais desanexar do path, apenas muda o estado.
		estado = Estado.PERSEGUINDO
		jogador = body
		tempo_desde_perda = 0.0
		_set_anim_state(false, true, false)


func _on_body_exited(body: Node3D):
	if body == jogador:
		call_deferred("_verificar_visibilidade_jogador_apos_saida")


func _on_body_entered_atack(body: Node3D):
	if body.is_in_group("player"):
		estado = Estado.ATACANDO

func _on_body_exited_atack(body: Node3D):
	if body.is_in_group("player"):
		if is_instance_valid(jogador):
			var jogador_ainda_em_area_de_visao_geral = false
			for area_node in todas_as_areas_de_visao:
				if is_instance_valid(area_node) and area_node.get_overlapping_bodies().has(jogador):
					jogador_ainda_em_area_de_visao_geral = true
					break
			if jogador_ainda_em_area_de_visao_geral:
				estado = Estado.PERSEGUINDO


func _verificar_visibilidade_jogador_apos_saida():
	if not is_instance_valid(jogador):
		return

	var jogador_ainda_visivel: bool = false
	for area_node in todas_as_areas_de_visao:
		if not is_instance_valid(area_node):
			continue
		if area_node.get_overlapping_bodies().has(jogador):
			jogador_ainda_visivel = true
			tempo_desde_perda = 0.0
			break

	if not jogador_ainda_visivel:
		jogador = null


# ========== TRANSFORMAÇÕES ==========
#- REMOVIDO: Funções _desanexar_do_path e _reativar_path não são mais necessárias
#- com a nova estrutura de nós.

func _suavizar_rotacao_pela_velocidade(delta: float):
	# Pega a direção do movimento atual, ignorando o eixo Y.
	var direcao_movimento = velocity * Vector3(1, 0, 1)

	# Se não houver movimento significativo, não faz nada.
	if direcao_movimento.length_squared() < 0.0001:
		return

	# Normaliza o vetor para ter apenas a direção.
	direcao_movimento = direcao_movimento.normalized()

	# Calcula o ângulo Y (rotação horizontal) com base na direção do movimento.
	var angulo_alvo_y = atan2(-direcao_movimento.x, -direcao_movimento.z)

	# Interpola suavemente a rotação atual em direção ao ângulo alvo.
	rotation.y = lerp_angle(rotation.y, angulo_alvo_y, velocidade_rot * delta)
	

# ========== VISUALIZAÇÃO ==========
# (Todas as suas funções de visualização permanecem as mesmas)
func _atualizar_visibilidade_debug_visuals():
	if cone_visual_mesh != null:
		cone_visual_mesh.visible = debug_visuals_visible
	if esfera_visual_mesh != null:
		esfera_visual_mesh.visible = debug_visuals_visible
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
		mesh.radius = (ataque_shape.shape as SphereShape3D).radius
		visual.mesh = mesh
	elif ataque_shape.shape is BoxShape3D:
		var mesh = BoxMesh.new()
		mesh.size = (ataque_shape.shape as BoxShape3D).size
		visual.mesh = mesh
	elif ataque_shape.shape is CapsuleShape3D:
		var mesh = CapsuleMesh.new()
		mesh.radius = (ataque_shape.shape as CapsuleShape3D).radius
		mesh.height = (ataque_shape.shape as CapsuleShape3D).height
		visual.mesh = mesh
	elif ataque_shape.shape is CylinderShape3D:
		var mesh = CylinderMesh.new()
		var cylinder_shape = ataque_shape.shape as CylinderShape3D
		mesh.top_radius = cylinder_shape.radius # CylinderShape3D só tem 'radius'
		mesh.bottom_radius = cylinder_shape.radius
		mesh.height = cylinder_shape.height
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
# (Todas as suas funções de criação de áreas permanecem as mesmas)
func _criar_area_visao_cone():
	area_visao_cone = Area3D.new()
	area_visao_cone.name = "AreaDeVisao"
	add_child(area_visao_cone)
	area_visao_cone.owner = self 

	var collision = CollisionShape3D.new()
	var shape = CylinderShape3D.new() 
	shape.radius = raio_cone
	shape.height = altura_cone
	collision.shape = shape
	collision.rotation_degrees = Vector3(90, 0, 0)
	collision.position = Vector3(0, 1.0, -altura_cone / 2.0) 
	area_visao_cone.add_child(collision)
	collision.owner = area_visao_cone

	var visual = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius = 0
	mesh.bottom_radius = raio_cone
	mesh.height = altura_cone
	visual.mesh = mesh
	visual.name = "ConeVisual"
	visual.rotation_degrees = collision.rotation_degrees 
	visual.position = collision.position

	var mat = StandardMaterial3D.new()
	mat.albedo_color = cor_cone
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.flags_transparent = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	visual.material_override = mat
	area_visao_cone.add_child(visual)
	visual.owner = area_visao_cone

	area_visao_cone.body_entered.connect(_on_body_entered)
	area_visao_cone.body_exited.connect(_on_body_exited)


func _criar_area_visao_esferica():
	area_visao_redonda = Area3D.new()
	area_visao_redonda.name = "AreaDeVisaoRedonda"
	add_child(area_visao_redonda)
	area_visao_redonda.owner = self

	var collision = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = esfera_raio
	shape.height = esfera_altura
	collision.shape = shape
	area_visao_redonda.add_child(collision)
	collision.owner = area_visao_redonda


	var visual = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius = esfera_raio
	mesh.bottom_radius = esfera_raio
	mesh.height = esfera_altura
	visual.mesh = mesh
	visual.name = "VisualRedondo"
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = esfera_cor
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.flags_transparent = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	visual.material_override = mat
	area_visao_redonda.add_child(visual)
	visual.owner = area_visao_redonda

	area_visao_redonda.body_entered.connect(_on_body_entered)
	area_visao_redonda.body_exited.connect(_on_body_exited)


func take_damage(amount: int):
	vida -= amount
	print(self.name, " tomou ", amount, " de dano. Vida restante: ", vida)
	if vida <= 0:
		die() 

func die():
	print(self.name, " morreu!")
	queue_free()

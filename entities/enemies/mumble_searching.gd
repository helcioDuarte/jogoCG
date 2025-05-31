extends CharacterBody3D

@export var cone_height: float = 15.0
@export var cone_radius: float = 5.0
@export var cone_color: Color = Color(0, 0.5, 1, 0.3)
@export var velocidade: float = 5.0
@export var tempo_para_voltar: float = 5.0

@export var quad_area_side_length: float = 4.0 # Lado do quadrado (base da caixa)
@export var quad_area_height: float = 7.0    # Altura da caixa de visão
@export var quad_area_color: Color = Color(1, 0.8, 0.2, 0.3) # Cor laranja/âmbar para diferenciar

# Novas variáveis para controlar a visibilidade das malhas de depuração
var cone_visual_mesh: MeshInstance3D = null
var quadrado_visual_mesh: MeshInstance3D = null
var debug_visuals_visible: bool = false # Começa com as visões escondidas

var area_visao_cone: Area3D = null
var area_visao_quadrada: Area3D = null
# Uma lista para facilitar a iteração por todas as áreas
var todas_as_areas_de_visao: Array[Area3D] = []

enum Estado {
	PATRULHANDO,
	PERSEGUINDO,
	VOLTANDO
}

var estado: Estado = Estado.PATRULHANDO
var jogador: Node3D = null
var tempo_desde_perda: float = 0.0

@onready var path_follow: PathFollow3D = get_parent()
@onready var animation_player: AnimationPlayer = path_follow.get_node("AnimationPlayer")
@onready var agente: NavigationAgent3D = $NavigationAgent3D

func _ready():
	animation_player.play("AnimaçãoDoCaminho")
	_criar_area_visao_cone()
	_criar_area_visao_quadrada()
	
	area_visao_cone = get_node_or_null("AreaDeVisao")
	if area_visao_cone:
		todas_as_areas_de_visao.append(area_visao_cone)
		# Obter a malha visual do cone
		cone_visual_mesh = area_visao_cone.get_node_or_null("ConeVisual")
		if cone_visual_mesh == null:
			printerr("ERRO: Malha 'ConeVisual' não encontrada dentro de 'AreaDeVisao'.")
		else:
			printerr("ERRO: 'AreaDeVisao' (cone) não encontrada.")
		
	area_visao_quadrada = get_node_or_null("AreaDeVisaoQuadrada")
	if area_visao_quadrada:
		todas_as_areas_de_visao.append(area_visao_quadrada)
		# Obter a malha visual do quadrado
		quadrado_visual_mesh = area_visao_quadrada.get_node_or_null("VisualQuadrado")
		if quadrado_visual_mesh == null:
			printerr("ERRO: Malha 'VisualQuadrado' não encontrada dentro de 'AreaDeVisaoQuadrada'.")
	else:
		printerr("ERRO: 'AreaDeVisaoQuadrada' não encontrada.")

	# Define o estado de visibilidade inicial para as malhas
	_atualizar_visibilidade_debug_visuals()

func _atualizar_visibilidade_debug_visuals():
	if cone_visual_mesh != null:
		cone_visual_mesh.visible = debug_visuals_visible
	if quadrado_visual_mesh != null:
		quadrado_visual_mesh.visible = debug_visuals_visible

func _alternar_visibilidade_debug_visuals():
	debug_visuals_visible = not debug_visuals_visible
	_atualizar_visibilidade_debug_visuals()
	if debug_visuals_visible:
		print("Visualização de depuração das áreas de visão ATIVADA.")
	else:
		print("Visualização de depuração das áreas de visão DESATIVADA.")


func _unhandled_input(event: InputEvent):
	# Verifica se o evento é um pressionamento de tecla, se a tecla foi recém-pressionada (não um eco)
	if event is InputEventKey and event.pressed and not event.is_echo():
		# Exemplo: Alternar com a tecla 'V'.
		# Você pode mudar para qualquer outra tecla (ex: KEY_H, KEY_F1)
		# ou, idealmente, usar uma Ação do Input Map (ex: "toggle_debug_vision").
		if event.keycode == KEY_F1: 
			_alternar_visibilidade_debug_visuals()

	# Se você quiser usar uma Ação do Input Map (recomendado):
	# 1. Vá em Projeto > Configurações do Projeto > Mapa de Entradas.
	# 2. Adicione uma nova ação, por exemplo, "toggle_debug_vision".
	# 3. Associe uma tecla a essa ação.
	# 4. Então, substitua a condição acima por:
	# if Input.is_action_just_pressed("toggle_debug_vision"):
	#     _alternar_visibilidade_debug_visuals()

func _physics_process(delta):
	match estado:
		Estado.PERSEGUINDO:
			_perseguir_jogador(delta)
		Estado.VOLTANDO:
			_retornar_para_path(delta)
		_:
			velocity = Vector3.ZERO
			move_and_slide()

func _perseguir_jogador(delta):
	if jogador == null or not jogador.is_inside_tree():
		tempo_desde_perda += delta
		if tempo_desde_perda > tempo_para_voltar:
			estado = Estado.VOLTANDO
			agente.target_position = path_follow.global_position
			print("🔙 Voltando para patrulha")
		return

	tempo_desde_perda = 0.0
	agente.target_position = jogador.global_transform.origin
	var next = agente.get_next_path_position()
	var dir = (next - global_position).normalized()
	velocity = dir * velocidade
	move_and_slide()

	var olhar = jogador.global_position
	olhar.y = global_position.y
	_suavizar_rotacao(jogador.global_position, delta)

func _reativar_path():
	var transform_anterior = global_transform
	var path_follow = $"../AlvoDoCaminho"  # Caminho relativo ao RootEnemy
	var root = get_parent()
	root.remove_child(self)
	path_follow.add_child(self)
	global_transform = transform_anterior

# Substitua a sua função _suavizar_rotacao por esta:
func _suavizar_rotacao(alvo: Vector3, delta: float, velocidade_rotacao: float = 2.0):
	# Calcula a direção do inimigo para o alvo, ignorando diferenças de altura (no plano XZ).
	var direcao_para_alvo = global_position.direction_to(alvo)
	direcao_para_alvo.y = 0 # Mantém o inimigo reto, sem inclinar para cima ou para baixo.

	# Se a direção no plano XZ for muito pequena (ex: alvo exatamente acima ou abaixo),
	# não há para onde virar horizontalmente. Evita erros e comportamento indefinido.
	if direcao_para_alvo.length_squared() < 0.0001: # Um valor pequeno para evitar divisão por zero ou NaN.
		return

	# Normaliza a direção APÓS zerar o Y, pois o comprimento do vetor mudou.
	direcao_para_alvo = direcao_para_alvo.normalized()

	# Calcula o ângulo de rotação (yaw) desejado.
	# Em Godot, a frente de um CharacterBody3D é geralmente o seu eixo -Z local.
	# atan2(componente_x, componente_z) retorna o ângulo para o qual o eixo +Z global apontaria.
	# Para fazer o eixo -Z local do inimigo apontar para 'direcao_para_alvo',
	# usamos -direcao_para_alvo.x e -direcao_para_alvo.z.
	var angulo_alvo_y = atan2(-direcao_para_alvo.x, -direcao_para_alvo.z)

	# Interpola suavemente a rotação atual no eixo Y em direção ao ângulo alvo.
	# 'lerp_angle' é crucial para interpolar ângulos corretamente (ex: de 350° para 10° pelo caminho mais curto).
	# 'velocidade_rotacao * delta' determina o quão rápido a interpolação acontece.
	# Um valor MENOR para 'velocidade_rotacao' resultará em uma rotação MAIS LENTA e SUAVE.
	rotation.y = lerp_angle(rotation.y, angulo_alvo_y, velocidade_rotacao * delta)


func _retornar_para_path(delta):
	if agente.is_navigation_finished():
		# 🔁 Realinha o inimigo exatamente com a posição e rotação do PathFollow3D
		global_position = path_follow.global_position
		global_rotation = path_follow.global_rotation

		# 🔄 Alinha o inimigo à frente do caminho
		var forward = -path_follow.global_transform.basis.z.normalized()
		_suavizar_rotacao(path_follow.global_position, delta)


		# ▶️ Volta a animação da patrulha
		estado = Estado.PATRULHANDO
		_reativar_path()
		animation_player.play("AnimaçãoDoCaminho")
		print("✅ Retornou à patrulha")
		return


	# Movimentação de retorno
	var next = agente.get_next_path_position()
	var dir = (next - global_position).normalized()
	velocity = dir * velocidade
	move_and_slide()

	var olhar = path_follow.global_position
	olhar.y = global_position.y
	look_at(olhar, Vector3.UP)

func _criar_area_visao_cone():
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

func _criar_area_visao_quadrada():
	var area_quadrada = Area3D.new()
	area_quadrada.name = "AreaDeVisaoQuadrada"
	add_child(area_quadrada) # Adiciona como filho do CharacterBody3D (inimigo)

	# 1. CollisionShape3D para detecção
	var collision_shape_quadrada = CollisionShape3D.new()
	area_quadrada.add_child(collision_shape_quadrada)

	var box_shape = BoxShape3D.new()
	# A propriedade 'size' do BoxShape3D é o tamanho total (largura, altura, profundidade)
	box_shape.size = Vector3(quad_area_side_length, quad_area_height, quad_area_side_length)
	collision_shape_quadrada.shape = box_shape
	# Por padrão, o BoxShape3D é centrado em sua própria origem.
	# Como collision_shape_quadrada está na origem da area_quadrada,
	# e area_quadrada está na origem do inimigo, a caixa ficará centrada no inimigo.

	# 2. MeshInstance3D para visualização
	var mesh_instance_quadrada = MeshInstance3D.new()
	mesh_instance_quadrada.name = "VisualQuadrado"
	area_quadrada.add_child(mesh_instance_quadrada) # Adiciona à Area3D

	var box_mesh = BoxMesh.new()
	box_mesh.size = box_shape.size # Mesmo tamanho da colisão para consistência visual
	mesh_instance_quadrada.mesh = box_mesh

	var material_quadrado = StandardMaterial3D.new()
	material_quadrado.albedo_color = quad_area_color
	material_quadrado.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA # Permite transparência
	material_quadrado.flags_transparent = true # Habilita a transparência no material
	# Opcional: para um visual similar ao cone (sem sombras próprias detalhadas)
	material_quadrado.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_instance_quadrada.material_override = material_quadrado

	# Assim como o CollisionShape, o MeshInstance e seu BoxMesh são centrados
	# em sua origem local, então a caixa visual também ficará centrada no inimigo.

	area_quadrada.body_entered.connect(_on_body_entered)
	area_quadrada.body_exited.connect(_on_body_exited)

func _desanexar_do_path():
	if get_parent() is PathFollow3D:
		var transform_anterior = global_transform  # Salva a posição global
		var root = get_parent().get_parent()  # RootEnemy
		get_parent().remove_child(self)
		root.add_child(self)
		global_transform = transform_anterior  # Restaura a posição global exata


func _on_body_entered(body):
	if body.is_in_group("player"):
		if estado != Estado.PERSEGUINDO:
			_desanexar_do_path()
			print("👀 Jogador detectado!")
			animation_player.stop()
			estado = Estado.PERSEGUINDO

		jogador = body # Atualiza a referência do jogador
		tempo_desde_perda = 0.0 # Reseta o tempo desde a perda, pois o jogador está visível
		# print("Jogador entrou em uma área de visão: ", body.name) # Log opcional


func _on_body_exited(body):
	if body == jogador: # Só processa se o corpo que saiu é o jogador que estamos rastreando
		# Adia a verificação para garantir que o estado da física (overlaps) esteja atualizado
		call_deferred("_verificar_visibilidade_jogador_apos_saida")

func _verificar_visibilidade_jogador_apos_saida():
	# Esta função é chamada de forma adiada após o jogador sair de uma área.

	if jogador == null: # Se por algum motivo o jogador já foi perdido, não faz nada
		return

	var jogador_ainda_visivel = false
	for area_visao in todas_as_areas_de_visao:
		if area_visao == null: # Verificação de segurança
			continue

		# Verifica se o jogador está atualmente sobrepondo esta área
		var corpos_na_area = area_visao.get_overlapping_bodies()
		if corpos_na_area.has(jogador):
			jogador_ainda_visivel = true
			break # Jogador encontrado em uma área, não precisa verificar mais

	if jogador_ainda_visivel:
		# Jogador saiu de UMA área, mas ainda está em OUTRA.
		print("Jogador saiu de uma área de visão específica, mas continua visível em outra.")
		# Garante que o tempo de perda seja resetado, pois o jogador ainda está sendo visto.
		# A função _on_body_entered da outra área já deve ter cuidado disso,
		# mas uma confirmação aqui pode ser útil.
		tempo_desde_perda = 0.0
	else:
		# Jogador NÃO está em NENHUMA das áreas de visão.
		print("🚶‍♂️ Jogador saiu de TODAS as áreas de visão.")
		jogador = null # Agora sim, o jogador é considerado perdido.
						# Isso fará com que o estado mude para VOLTANDO em _physics_process

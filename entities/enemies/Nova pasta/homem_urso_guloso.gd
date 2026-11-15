extends CharacterBody3D

# --- Configurações de Comportamento ---
@export var velocidade: float = 4.32
@export var dano_ataque: float = 15.0
@export var vida: float = 150
@export var velocidade_rot: float = 5.0
@export var ataque_cooldown: float = 1.67

# --- Estados da IA ---
enum Estado { PERSEGUINDO, ATACANDO, MORTO }
var estado: Estado = Estado.PERSEGUINDO

# --- Referências ---
var jogador: Node3D
var _tempo_desde_ultimo_ataque: float = 0.0

# --- Nós da Cena ---
@onready var agente: NavigationAgent3D = $NavigationAgent3D
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var ataque_area: Area3D = $AttackRangeArea

# ================================= INICIALIZAÇÃO =================================
func _ready():
	print("Inimigo ", self.name, " está iniciando.")
	jogador = get_tree().get_first_node_in_group("player")
	if not is_instance_valid(jogador) and get_tree().current_scene:
		jogador = get_tree().current_scene.find_child("player", true, false)
	if not is_instance_valid(jogador):
		print("ERRO: Inimigo '%s' não encontrou o jogador! Desativando." % self.name)
		set_physics_process(false)
		return
	print("Inimigo '%s' encontrou o jogador: %s" % [self.name, jogador.name])
	ataque_area.body_entered.connect(_on_body_entered_atack)
	ataque_area.body_exited.connect(_on_body_exited_atack)
	if not $VideoStreamPlayer.finished.is_connected(_on_video_finished):
		$VideoStreamPlayer.finished.connect(_on_video_finished)

# ================================= CICLO DE JOGO =================================
func _physics_process(delta: float):
	if estado == Estado.MORTO:
		return

	_tempo_desde_ultimo_ataque += delta

	match estado:
		Estado.PERSEGUINDO:
			_perseguir_jogador(delta)
		Estado.ATACANDO:
			_atacar_jogador(delta)


# ================================= COMPORTAMENTOS =================================
func _perseguir_jogador(delta: float):
	# Garante que a condição de ataque esteja desativada para permitir a corrida.
	animation_tree.set("parameters/conditions/attack", false)

	if not is_instance_valid(jogador):
		velocity = Vector3.ZERO
		move_and_slide()
		return

	agente.target_position = jogador.global_transform.origin
	
	var proximo_ponto = agente.get_next_path_position()
	var direcao = global_position.direction_to(proximo_ponto)
	
	velocity = direcao * velocidade
	move_and_slide()
	_suavizar_rotacao_pela_velocidade(delta)


func _atacar_jogador(delta: float):
	# Ativa a condição de ataque no AnimationTree.
	animation_tree.set("parameters/conditions/attack", true)
	velocity = Vector3.ZERO
	move_and_slide()

	if is_instance_valid(jogador):
		var direcao_jogador = (jogador.global_position - global_position) * Vector3(1, 0, 1)
		if direcao_jogador.length_squared() > 0.0001:
			direcao_jogador = direcao_jogador.normalized()
			var angulo_alvo_y = atan2(direcao_jogador.x, direcao_jogador.z)
			rotation.y = lerp_angle(rotation.y, angulo_alvo_y, velocidade_rot * delta)

		if estado == Estado.ATACANDO and ataque_area.get_overlapping_bodies().has(jogador) and _tempo_desde_ultimo_ataque >= ataque_cooldown:
			_tempo_desde_ultimo_ataque = 0.0
			var painel_inventario = jogador.get_node_or_null("InventoryPanel")
			if painel_inventario and painel_inventario.has_method("take_damage"):
				painel_inventario.take_damage(dano_ataque)


# ================================= DETECÇÃO DE ATAQUE =================================
func _on_body_entered_atack(body: Node3D):
	if estado == Estado.MORTO:
		return
	if body == jogador:
		estado = Estado.ATACANDO

func _on_body_exited_atack(body: Node3D):
	if estado == Estado.MORTO:
		return
	if body == jogador:
		estado = Estado.PERSEGUINDO


# ================================= DANO E MORTE =================================
func take_damage(amount: int):
	if estado == Estado.MORTO:
		return
		
	vida -= amount
	if vida <= 0:
		die()

func die():
	if estado == Estado.MORTO:
		return
	print("INIMIGO '%s' ESTÁ MORRENDO!" % self.name)

	estado = Estado.MORTO
	$VideoStreamPlayer.play()
	agente.set_velocity(Vector3.ZERO)
	velocity = Vector3.ZERO
	move_and_slide()

	# Como não há animação de morte, desativamos a árvore de animação.
	# O inimigo ficará congelado na última pose.
	animation_tree.active = false

	if is_instance_valid(ataque_area):
		ataque_area.monitoring = false
	var corpo_colisao = find_child("CollisionShape3D", true, false)
	if corpo_colisao:
		corpo_colisao.set_deferred("disabled", true)

func _on_video_finished():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	TransitionManager.start("res://scenes/victory.tscn")

# ================================= UTILITÁRIOS =================================
func _suavizar_rotacao_pela_velocidade(delta: float):
	var direcao_movimento = velocity * Vector3(1, 0, 1)

	if direcao_movimento.length_squared() < 0.0001:
		return

	direcao_movimento = direcao_movimento.normalized()
	
	var angulo_alvo_y = atan2(direcao_movimento.x, direcao_movimento.z)
	
	rotation.y = lerp_angle(rotation.y, angulo_alvo_y, velocidade_rot * delta)
#	rotation.y = angulo_alvo_y

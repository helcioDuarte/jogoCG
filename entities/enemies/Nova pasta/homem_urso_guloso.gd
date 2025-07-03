extends CharacterBody3D

# --- Configurações de Comportamento ---
@export var velocidade: float = 13.0
@export var dano_ataque: float = 15.0
@export var vida: float = 150
@export var velocidade_rot: float = 5.0

# --- Estados da IA ---
enum Estado { PERSEGUINDO, ATACANDO, MORTO }
var estado: Estado = Estado.PERSEGUINDO

# --- Referências ---
var jogador: Node3D

# --- Nós da Cena ---
@onready var agente: NavigationAgent3D = $NavigationAgent3D
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var ataque_area: Area3D = $AttackRangeArea

# ================================= INICIALIZAÇÃO =================================
func _ready():
	print("Inimigo ", self.name, " está iniciando.")
	jogador = get_tree().get_first_node_in_group("player")
	if not is_instance_valid(jogador):
		print("ERRO: Inimigo '%s' não encontrou o jogador! Desativando." % self.name)
		set_physics_process(false)
		return
	print("Inimigo '%s' encontrou o jogador: %s" % [self.name, jogador.name])
	ataque_area.body_entered.connect(_on_body_entered_atack)
	ataque_area.body_exited.connect(_on_body_exited_atack)
	$VideoStreamPlayer.finished.connect(_on_video_finished)

# ================================= CICLO DE JOGO =================================
func _physics_process(delta: float):
	if estado == Estado.MORTO:
		return

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


# ================================= DETECÇÃO DE ATAQUE =================================
func _on_body_entered_atack(body: Node3D):
	if body == jogador:
		estado = Estado.ATACANDO

func _on_body_exited_atack(body: Node3D):
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
	print("INIMIGO '%s' ESTÁ MORRENDO!" % self.name)
	if estado == Estado.MORTO:
		return

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
	get_tree().change_scene_to_file("res://scenes/victory.tscn")

# ================================= UTILITÁRIOS =================================
func _suavizar_rotacao_pela_velocidade(delta: float):
	var direcao_movimento = velocity * Vector3(1, 0, 1)

	if direcao_movimento.length_squared() < 0.0001:
		return

	direcao_movimento = direcao_movimento.normalized()
	
	var angulo_alvo_y = atan2(direcao_movimento.x, direcao_movimento.z)
	
	rotation.y = lerp_angle(rotation.y, angulo_alvo_y, velocidade_rot * delta)
#	rotation.y = angulo_alvo_y

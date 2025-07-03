extends Node3D # Ou o tipo de nó raiz da sua sala

@export var pontos_spawn_inimigos: Array[Marker3D] = [] # ALTERADO para um Array
@export var pontos_spawn_itens: Array[Marker3D] = []
@export var cena_inimigo: PackedScene
@export var ponto_de_spawn: Marker3D

var inimigo_instanciado: Node3D = null

# É necessário ter a referência do jogador exportada no script
@export var no_jogador: CharacterBody3D

func _ready():
	# Lógica dos inimigos (agora baseada na lista)
	if not TransitionManager.inimigos_para_spawnar.is_empty():
		spawn_inimigos()
	TransitionManager.inimigos_para_spawnar.clear()

	# Lógica dos itens
	if not TransitionManager.itens_para_spawnar.is_empty():
		spawn_itens()
	TransitionManager.itens_para_spawnar.clear()

# Função para spawnar os itens
func spawn_itens():
	var itens_a_spawnar = TransitionManager.itens_para_spawnar
	var quantidade_para_spawnar = min(itens_a_spawnar.size(), pontos_spawn_itens.size())
	
	if pontos_spawn_itens.is_empty() and not itens_a_spawnar.is_empty():
		printerr("AVISO: Existem itens para spawnar, mas nenhum 'ponto_spawn_itens' foi configurado em ", name)
		return

	print("Spawning ", quantidade_para_spawnar, " itens na sala.")
	for i in range(quantidade_para_spawnar):
		var cena_item = itens_a_spawnar[i]
		var ponto_spawn = pontos_spawn_itens[i]
		if not cena_item or not is_instance_valid(ponto_spawn): continue
			
		var item_instanciado = cena_item.instantiate()
		add_child(item_instanciado)
		item_instanciado.global_position = ponto_spawn.global_position

# Função para spawnar inimigos (agora no plural e reescrita)
func spawn_inimigos():
	# Verificação essencial
	if not is_instance_valid(no_jogador):
		printerr("ERRO: 'no_jogador' não está configurado no Inspetor do controladorDaSala!")
		return

	var inimigos_a_spawnar = TransitionManager.inimigos_para_spawnar
	var quantidade_para_spawnar = min(inimigos_a_spawnar.size(), pontos_spawn_inimigos.size())

	if pontos_spawn_inimigos.is_empty() and not inimigos_a_spawnar.is_empty():
		printerr("AVISO: Existem inimigos para spawnar, mas nenhum 'ponto_spawn_inimigos' foi configurado em ", name)
		return

	print("Spawning ", quantidade_para_spawnar, " inimigos na sala.")
	for i in range(quantidade_para_spawnar):
		var cena_inimigo = inimigos_a_spawnar[i]
		var ponto_spawn = pontos_spawn_inimigos[i]
		if not cena_inimigo or not is_instance_valid(ponto_spawn): continue

		var inimigo_instanciado = cena_inimigo.instantiate()
		add_child(inimigo_instanciado)
		inimigo_instanciado.global_position = ponto_spawn.global_position
		
		# Se o seu script de inimigo ainda precisar da referência do jogador
		if inimigo_instanciado.has_method("iniciar_perseguicao_imediata"):
			inimigo_instanciado.iniciar_perseguicao_imediata(no_jogador)

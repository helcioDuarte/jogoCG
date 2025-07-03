extends Node3D # Ou o tipo de nó raiz da sua sala

@export var cena_inimigo: PackedScene

@export var ponto_de_spawn: Marker3D

var inimigo_instanciado: Node3D = null

# É necessário ter a referência do jogador exportada no script
@export var no_jogador: CharacterBody3D

func _ready():
	if TransitionManager.deve_spawnar_inimigo_na_proxima_sala:
		spawn_inimigo()

	TransitionManager.deve_spawnar_inimigo_na_proxima_sala = false


# Em controladorDaSala.gd

func spawn_inimigo():
	

	# Verificações
	if not cena_inimigo or not ponto_de_spawn or not is_instance_valid(no_jogador):
		printerr("ERRO: Verifique se cena_inimigo, ponto_de_spawn e no_jogador estão configurados no Inspetor!")
		return
	if is_instance_valid(inimigo_instanciado):
		return
		
	print("Inimigo spawnado na sala!")
	inimigo_instanciado = cena_inimigo.instantiate()
	add_child(inimigo_instanciado)
	inimigo_instanciado.global_position = ponto_de_spawn.global_position
	
	# Usamos o método direto e mais confiável para iniciar a perseguição
	inimigo_instanciado.iniciar_perseguicao_imediata(no_jogador)

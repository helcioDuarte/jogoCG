extends Node3D # Ou o tipo de nó raiz da sua sala

@export var cena_inimigo: PackedScene

@export var ponto_de_spawn: Marker3D

var inimigo_instanciado: Node3D = null


func _ready():
	if TransitionManager.deve_spawnar_inimigo_na_proxima_sala:
		spawn_inimigo()

	TransitionManager.deve_spawnar_inimigo_na_proxima_sala = false


func spawn_inimigo():
	if not cena_inimigo or not ponto_de_spawn:
		printerr("Cena do inimigo ou ponto de spawn não definidos na sala!")
		return

	if is_instance_valid(inimigo_instanciado):
		return
		
	print("Spawnado")
	inimigo_instanciado = cena_inimigo.instantiate()
	add_child(inimigo_instanciado)
	inimigo_instanciado.global_position = ponto_de_spawn.global_position
	
	inimigo_instanciado.scan_for_player_on_spawn()

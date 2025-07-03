extends MeshInstance3D

@export var destination = "res://scenes/sala.tscn"
@export var open = true
@export var message: Array[String] = ["Trancado..."]
@export var cenas_inimigos_para_spawnar: Array[PackedScene] = []
@export var cenas_itens_para_spawnar: Array[PackedScene] = [] 
@export var key = ""

var player = null
var canEnter = false
var openBuffer = 0


func enter(body):
	if body.name == "player":
		player = player if player != null else body
		canEnter = true

func leave(body):
	if body.name == "player":
		canEnter = false

func _process(_delta: float) -> void:
	if !canEnter:
		return
	
	if Input.is_action_just_pressed("interact"):
		if open:
			
			# 1. Antes de transicionar, definimos os estados no nosso gerenciador global.
			# TransitionManager.deve_spawnar_inimigo_na_proxima_sala = spawna_inimigo_nesta_sala # REMOVIDO
			TransitionManager.inimigos_para_spawnar = cenas_inimigos_para_spawnar # NOVO
			TransitionManager.itens_para_spawnar = cenas_itens_para_spawnar
			
			TransitionManager.setRoom(name)
			$"../PortaAbrindo".play()
			TransitionManager.start(destination)

		elif key == "chave_bandejao" and player.inventory.inventory.get_inventory_item_by_id("chave_bandejao") != {}:
			TransitionManager.start("res://scenes/overworldBoss.tscn")

		elif openBuffer > 0: # só tenta abrir a porta de novo após fechar o diálogo
			openBuffer -= 1
		else:
			openBuffer = message.size()
			$textBox.start_dialogue(message)
			
func save_state() -> Dictionary:
	return {
		"open": open
	}

func load_state(data: Dictionary):
	if data.has("has_been_triggered"):
		open = data["open"]

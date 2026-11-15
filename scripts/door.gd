extends MeshInstance3D

@export var destination = "res://scenes/sala.tscn"
@export var open = true
@export var message: Array[String] = ["Trancado..."]
@export var cenas_inimigos_para_spawnar: Array[PackedScene] = []
@export var cenas_itens_para_spawnar: Array[PackedScene] = [] 
@export var key = ""

var player = null
var canEnter = false
var _was_paused = false

func _ready():
	add_to_group("savable")
	if key == "chave_bandejao":
		destination = "res://scenes/overworldBoss.tscn"

func enter(body):
	if body.is_in_group("player") or body.name == "player":
		player = player if player != null else body
		canEnter = true

func leave(body):
	if body.is_in_group("player") or body.name == "player":
		canEnter = false

func _process(_delta: float) -> void:
	if get_tree().paused:
		_was_paused = true
		return
	if _was_paused:
		_was_paused = false
		return
	if TransitionManager.is_transitioning or !canEnter:
		return
	
	if Input.is_action_just_pressed("interact"):
		if open:
			if not ResourceLoader.exists(destination):
				push_error("Door destination does not exist: %s" % destination)
				return
			# 1. Antes de transicionar, definimos os estados no nosso gerenciador global.
			# TransitionManager.deve_spawnar_inimigo_na_proxima_sala = spawna_inimigo_nesta_sala # REMOVIDO
			TransitionManager.inimigos_para_spawnar = cenas_inimigos_para_spawnar # NOVO
			TransitionManager.itens_para_spawnar = cenas_itens_para_spawnar
			
			TransitionManager.setRoom(name)
			var porta_som = get_node_or_null("../PortaAbrindo")
			if porta_som:
				porta_som.play()
			TransitionManager.start(destination)

		elif key == "chave_bandejao" and is_instance_valid(player) and player.inventory.get_inventory_item_by_id("chave_bandejao") != {}:
			var boss_scene = "res://scenes/overworldBoss.tscn"
			if not ResourceLoader.exists(boss_scene):
				push_error("Door destination does not exist: %s" % boss_scene)
				return
			open = true
			destination = boss_scene
			player.inventory.remove_item_from_inventory("chave_bandejao", 1)
			TransitionManager.inimigos_para_spawnar = cenas_inimigos_para_spawnar
			TransitionManager.itens_para_spawnar = cenas_itens_para_spawnar
			TransitionManager.setRoom(name)
			var porta_som = get_node_or_null("../PortaAbrindo")
			if porta_som:
				porta_som.play()
			TransitionManager.start(destination)

		else:
			$textBox.start_dialogue(message.duplicate(), player)
			
func save_state() -> Dictionary:
	return {
		"open": open
	}

func load_state(data: Dictionary):
	if data.has("open"):
		open = data["open"]

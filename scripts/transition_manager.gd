extends Node

var transition_layer_scene = preload("res://scenes/transition_layer.tscn")
var is_transitioning = false
var scene_states = {}
var inventoryState = {}
var inventoryPath = ""
var currentRoom = ""
var last_gameplay_scene: String = "res://scenes/banheiro.tscn"
var inimigos_para_spawnar: Array[PackedScene] = []
var itens_para_spawnar: Array[PackedScene] = [] # Linha adicionada
var _skip_next_save_on_transition: bool = false

func reset_state():
	scene_states.clear()
	inventoryState.clear()
	currentRoom = ""
	last_gameplay_scene = "res://scenes/overworld.tscn"
	inimigos_para_spawnar.clear()
	itens_para_spawnar.clear()
	_skip_next_save_on_transition = false

func get_saved_scene() -> String:
	return last_gameplay_scene if not last_gameplay_scene.is_empty() else "res://scenes/banheiro.tscn"

# Função que inicia a transição
func start(scene_path: String):
	if is_transitioning:
		return
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		push_error("Failed to load scene: %s" % scene_path)
		inimigos_para_spawnar.clear()
		itens_para_spawnar.clear()
		_skip_next_save_on_transition = false
		return

	is_transitioning = true
	if _skip_next_save_on_transition:
		_skip_next_save_on_transition = false
	else:
		_save_current_scene_state()

	var instance = transition_layer_scene.instantiate()
	get_tree().root.add_child(instance)

	var radial_blur_node = instance.get_node("ColorRect")
	var radial_blur_material = radial_blur_node.material
	var loading_label = instance.get_node("LoadingLabel")
	var black_node = instance.get_node("black")
	var fade_material = black_node.material

	radial_blur_node.visible = true
	black_node.visible = false
	loading_label.visible = true
	
	var tween_in = get_tree().create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween_in.tween_property(radial_blur_material, "shader_parameter/progress", 1.0, 0.7)
	await tween_in.finished

	if not is_instance_valid(instance):
		inimigos_para_spawnar.clear()
		itens_para_spawnar.clear()
		is_transitioning = false
		return

	loading_label.visible = false
	radial_blur_node.visible = false
	black_node.visible = true
	
	var error = get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("Failed to load scene: %s" % scene_path)
		inimigos_para_spawnar.clear()
		itens_para_spawnar.clear()
		if is_instance_valid(instance):
			instance.queue_free()
		is_transitioning = false
		return

	# Espera dois frames para garantir que a nova cena foi inicializada
	await get_tree().process_frame
	await get_tree().process_frame

	_load_new_scene_state()
	inimigos_para_spawnar.clear()
	itens_para_spawnar.clear()

	if is_instance_valid(instance):
		var tween_out = get_tree().create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween_out.tween_property(fade_material, "shader_parameter/progress", 1.0, 0.7)
		await tween_out.finished

	if is_instance_valid(instance):
		instance.queue_free()
	is_transitioning = false

# Função para salvar o estado da cena atual
func _save_current_scene_state():
	var current_scene = get_tree().current_scene
	if current_scene == null or current_scene.scene_file_path.is_empty():
		return

	if current_scene.scene_file_path != "res://scenes/save.tscn" and current_scene.scene_file_path != "res://scenes/menu.tscn":
		last_gameplay_scene = current_scene.scene_file_path
		
	var state = {}
	var savable_nodes = get_tree().get_nodes_in_group("savable")
	for node in savable_nodes:
		if node.has_method("save_state"):
			state[str(node.get_path())] = node.call("save_state")
		elif node.name == "InventoryPanel":
			inventoryState = node.call("save_persistent_state")
			
	if !state.is_empty():
		scene_states[current_scene.scene_file_path] = state

# Função para carregar o estado da nova cena
func _load_new_scene_state():
	var current_scene = get_tree().current_scene
	if current_scene == null:
		return

	var inventory_node = current_scene.find_child("InventoryPanel", true, false)
	if inventory_node != null and not inventoryState.is_empty():
		inventory_node.call("load_persistent_state", inventoryState)
	if !scene_states.has(current_scene.scene_file_path):
		return

	var state = scene_states[current_scene.scene_file_path]
	for node_path_str in state:
		var node = current_scene.get_node_or_null(node_path_str)
		if node != null and node.has_method("load_state"):
			node.call("load_state", state[node_path_str])

# Salva o estado atual do jogo em um arquivo.
func save_game():
	_save_current_scene_state()

	# Agrupa todos os dados persistentes em um único dicionário
	var full_save_data = {
		"scene_states": scene_states,
		"inventory_state": inventoryState,
		"current_room": currentRoom,
		"saved_scene": get_saved_scene()
	}

	var file = FileAccess.open("user://save.dat", FileAccess.WRITE)
	if file == null:
		push_error("Erro ao abrir arquivo de save para escrita.")
		return
	# Usa JSON.stringify para criar um arquivo de texto legível e compatível
	file.store_string(JSON.stringify(full_save_data))
	file.close()
	#print("Jogo Salvo.")

# Carrega o estado do jogo e inicia a transição para a cena salva.
func load_game() -> bool:
	var file_path = "user://save.dat"
	if not FileAccess.file_exists(file_path):
		#print("Arquivo de save não encontrado.")
		return false

	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return false
	var content = file.get_as_text()
	file.close()

	var full_save_data = JSON.parse_string(content)
	if typeof(full_save_data) != TYPE_DICTIONARY:
		print("Erro ao ler os dados do arquivo de save.")
		return false

	# Restaura as variáveis do manager com os dados do arquivo
	var loaded_states = full_save_data.get("scene_states", {})
	self.scene_states = loaded_states if typeof(loaded_states) == TYPE_DICTIONARY else {}
	var loaded_inventory = full_save_data.get("inventory_state", {})
	self.inventoryState = loaded_inventory if typeof(loaded_inventory) == TYPE_DICTIONARY else {}
	self.currentRoom = str(full_save_data.get("current_room", ""))
	var saved_scene = str(full_save_data.get("saved_scene", "res://scenes/banheiro.tscn"))
	self.last_gameplay_scene = saved_scene if not saved_scene.is_empty() else "res://scenes/banheiro.tscn"
	self._skip_next_save_on_transition = true
	return true

func setRoom(room: String):
	currentRoom = room
	
func getRoom():
	return currentRoom

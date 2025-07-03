extends CanvasLayer

@export var item_icon_scene: PackedScene

@onready var health_indicator = %HealthDisplay
var max_health: float = 100.0
var current_health: float = max_health

const HEALTHY_COLOR: Color = Color.GREEN
const DAMAGED_COLOR: Color = Color.YELLOW
const CRITICAL_COLOR: Color = Color.RED
const FULL_HEALTH_COLOR: Color = Color(0.2, 0.8, 0.2)

@onready var item_list_container: HBoxContainer = %ItemListContainer
@onready var equipped_item_label: Label = %EquippedItemLabel
@onready var item_description_label: Label = %ItemDescriptionLabel
@onready var use_equip_button: Button = %UseEquipButton
@onready var combine_button: Button = %CombineButton
@onready var prev_item_button: Button = %PrevItemButton
@onready var next_item_button: Button = %NextItemButton

var inventory: Array[Dictionary] = []

var current_item_index: int = -1
var equipped_item_id = null

var is_combine_mode: bool = false
var first_item_for_combination: Dictionary = {}

const MAX_VISIBLE_CAROUSEL_ITEMS = 3

const ITEM_DATA = {
	"cano": {"name": "Cano", "id": "cano", "description": "Um cano de metal. Dano baixo.", "type": "weapon", "damage": 10, "icon_path": "res://textures/icones/Cano.JPG", "combinable": false},
	"faca": {"name": "Faca", "id": "faca", "description": "Uma faca afiada. Dano moderado.", "type": "weapon", "damage": 15, "icon_path": "res://textures/icones/Faca.JPG", "combinable": false},
	"green_herb": {"name": "Erva Verde", "id": "green_herb", "description": "Uma erva medicinal comum.", "type": "consumable", "icon_path": "res://textures/icones/GreenHerb.JPG", "quantity": 1, "heal_amount": 20, "combinable": true},
	"red_herb": {"name": "Erva Vermelha", "id": "red_herb", "description": "Uma erva rara. Potencializa outras ervas.", "type": "ingredient", "icon_path": "res://textures/icones/RedHerb.JPG", "quantity": 1, "combinable": true},
	"medkit": {"name": "Kit Médico", "id": "medkit", "description": "Recupera bastante vida.", "type": "consumable", "icon_path": "res://textures/icones/MedKit.JPG", "quantity": 1, "heal_amount": 60, "combinable": false},
	"green_herb_plus": {"name": "Erva Verde+", "id": "green_herb_plus", "description": "Duas ervas verdes combinadas. Cura moderada.", "type": "consumable", "icon_path": "res://textures/icones/GreenHerb+.JPG", "quantity": 1, "heal_amount": 50, "combinable": true},
	"green_herb_plus_plus": {"name": "Erva Verde++", "id": "green_herb_plus_plus", "description": "Uma potente mistura de ervas verdes. Cura alta.", "type": "consumable", "icon_path": "res://textures/icones/GreenHerb++.JPG", "quantity": 1, "heal_amount": 100, "combinable": false},
	"herb_mix": {"name": "Mistura de Ervas", "id": "herb_mix", "description": "Ervas verde e vermelha combinadas. Cura significativa.", "type": "consumable", "icon_path": "res://textures/icones/MixHerb.JPG", "quantity": 1, "heal_amount": 80, "combinable": false},
	"revolver": {"name": "Revólver", "id": "revolver", "description": "Um revólver calibre .38.", "type": "weapon", "damage": 35, "icon_path": "res://textures/icones/Revolver.JPG", "combinable": true, "current_ammo": 0, "max_ammo": 6},
	"revolver_ammo": {"name": "Bala .38", "id": "revolver_ammo", "description": "Uma bala calibre .38.", "type": "ingredient", "icon_path": "res://textures/icones/Municao.JPG", "quantity": 1, "combinable": true},
	"red_bear": {"name": "Urso Vermelho", "id": "red_bear", "description": "Um velho urso de pelúcia vermelho. Onde será que eu uso isso?", "type": "puzzle", "icon_path": "res://textures/icones/Urso vermelho.JPG", "quantity": 1},
	"blue_bear": {"name": "Urso Azul", "id": "blue_bear", "description": "Um velho urso de pelúcia azul. Onde será que eu uso isso?", "type": "puzzle", "icon_path": "res://textures/icones/Urso azul.JPG", "quantity": 1},
	"green_bear": {"name": "Urso Verde", "id": "green_bear", "description": "Um velho urso de pelúcia verde. Onde será que eu uso isso?", "type": "puzzle", "icon_path": "res://textures/icones/Urso verde.JPG", "quantity": 1},
	"yellow_bear": {"name": "Urso Amarelo", "id": "yellow_bear", "description": "Um velho urso de pelúcia amarelo. Onde será que eu uso isso?", "type": "puzzle", "icon_path": "res://textures/icones/Urso amarelo.JPG", "quantity": 1},
	"black_bear": {"name": "Urso Preto", "id": "black_bear", "description": "Um velho urso de pelúcia preto. Onde será que eu uso isso?", "type": "puzzle", "icon_path": "res://textures/icones/Urso preto.JPG", "quantity": 1},
	"chave_bandejao": {"name": "Chave do Bandejão", "id": "chave_bandejao", "description": "Uma chave ornamentada, parece importante.", "type": "key", "icon_path": "res://textures/icones/Chave.JPG"}
}

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	update_health_indicator()
	# debug itens
	add_item_to_inventory("green_herb", 4)
	add_item_to_inventory("red_herb", 2)
	add_item_to_inventory("medkit", 1)
	add_item_to_inventory("revolver_ammo", 8)


	if not inventory.is_empty():
		current_item_index = 0
	
	update_ui_elements()


func pause():
	if not is_visible():
		# get the current frame and use it as background
		$background.texture = ImageTexture.create_from_image(get_viewport().get_texture().get_image())

func _input(event):
	if not get_viewport().gui_is_dragging() and not event.is_echo() and visible:
		if event.is_action_pressed("right"):
			cycle_inventory(1)
			get_viewport().set_input_as_handled()

		if event.is_action_pressed("left"):
			cycle_inventory(-1)
			get_viewport().set_input_as_handled()
		
		if event.is_action_pressed("interact"):
			_on_use_equip_button_pressed()
			get_viewport().set_input_as_handled()
		if event.is_action_pressed("something_else"):
			_on_combine_button_pressed()
			get_viewport().set_input_as_handled()
		

func update_ui_elements():
	update_inventory_display()
	update_equipped_item_display()
	update_combine_button_text_and_state()
	update_use_equip_button_text_and_state()

func take_damage(amount):
	current_health = clamp(current_health - amount, 0.0, max_health)
	update_health_indicator()

func heal(amount):
	current_health = clamp(current_health + amount, 0.0, max_health)
	update_health_indicator()

func full_heal():
	current_health = max_health
	update_health_indicator()

func update_health_indicator():
	var p = 0.0
	if max_health > 0:
		p = current_health / max_health
	
	if health_indicator:
		if p >= 1.0:
			health_indicator.color = FULL_HEALTH_COLOR
		elif p > 0.66:
			health_indicator.color = HEALTHY_COLOR
		elif p > 0.33:
			health_indicator.color = DAMAGED_COLOR
		else:
			health_indicator.color = CRITICAL_COLOR

func add_item_to_inventory(item_id, quantity_to_add = 1):
	if not ITEM_DATA.has(item_id):
		#print("Erro: Item desconhecido: ", item_id)
		return
	var existing_idx = -1
	for i in inventory.size():
		if inventory[i].id == item_id:
			existing_idx = i
			break
	
	var item_tpl_from_const = ITEM_DATA[item_id]
	
	if existing_idx != -1:
		inventory[existing_idx].quantity += quantity_to_add
	else:
		var new_item_instance = item_tpl_from_const.duplicate(true)
		new_item_instance.quantity = quantity_to_add
		inventory.append(new_item_instance)
		if current_item_index == -1 and inventory.size() == 1:
			current_item_index = 0
	
	if is_visible():
		update_ui_elements()


func remove_item_from_inventory(item_id, quantity_to_remove = 1):
	for i in range(inventory.size() - 1, -1, -1):
		var item = inventory[i]
		if item.id == item_id:
			if item.has("quantity"):
				item.quantity -= quantity_to_remove
				if item.quantity <= 0:
					if equipped_item_id == item_id:
						unequip_current_item()
					inventory.remove_at(i)
			else:
				if equipped_item_id == item_id:
					unequip_current_item()
				inventory.remove_at(i)

			if inventory.is_empty():
				current_item_index = -1
			elif current_item_index >= i and current_item_index > 0 and item.quantity <= 0:
				current_item_index = max(0, current_item_index -1)
			elif current_item_index >= inventory.size():
				current_item_index = inventory.size() -1
			
			if is_visible():
				update_ui_elements()
			
			return true
	return false

func get_item_count(item_id):
	for item_instance in inventory:
		if item_instance.id == item_id:
			return item_instance.get("quantity", 0) # Default to 0 if no quantity
	return 0
	
func get_inventory_item_by_id(item_id):
	for item_instance in inventory:
		if item_instance.id == item_id:
			return item_instance
	return {}


func update_inventory_display():
	for child in item_list_container.get_children():
		child.queue_free()
	
	var btns_disabled = inventory.is_empty()
	prev_item_button.disabled = btns_disabled
	next_item_button.disabled = btns_disabled
	
	if inventory.is_empty():
		item_description_label.text = "Inventário Vazio"
		current_item_index = -1
		return
	if current_item_index < 0 || current_item_index >= inventory.size():
		current_item_index = 0 if not inventory.is_empty() else -1
		if current_item_index == -1:
			return
	
	var sel_item_data = inventory[current_item_index]
	var description_text = sel_item_data.name + "\n" + sel_item_data.description
	
	if sel_item_data.has("current_ammo"):
		%ammo.text = "Munição: %d/%d" % [int(sel_item_data.current_ammo), int(sel_item_data.max_ammo)]
	else:
		%ammo.text = ""
	item_description_label.text = description_text
	
	var disp_indices = []
	var inv_size = inventory.size()
	
	if inv_size <= MAX_VISIBLE_CAROUSEL_ITEMS:
		for i in inv_size:
			disp_indices.append(i)
	else:
		var offset = MAX_VISIBLE_CAROUSEL_ITEMS / 2
		for i in MAX_VISIBLE_CAROUSEL_ITEMS:
			var idx = (current_item_index - offset + i + inv_size) % inv_size
			disp_indices.append(idx)
	for i in disp_indices:
		var item_d = inventory[i]
		var icon_inst = item_icon_scene.instantiate()
		item_list_container.add_child(icon_inst)
		icon_inst.set_item(item_d)
		icon_inst.item_clicked.connect(_on_item_icon_clicked.bind(item_d))

		if i == current_item_index:
			icon_inst.set_highlight_mode("selected")
		elif is_combine_mode and first_item_for_combination.has("id") and item_d.id == first_item_for_combination.id and i == first_item_for_combination.get("original_inventory_index", -10):
			icon_inst.set_highlight_mode("combine_source")
		else: icon_inst.set_highlight_mode("normal")

func cycle_inventory(direction):
	if inventory.is_empty():
		return
	var old_idx = current_item_index
	current_item_index = (current_item_index + direction + inventory.size()) % inventory.size()
	if old_idx != current_item_index:
		update_ui_elements()

func _on_item_icon_clicked(item_data_clicked_from_signal):
	for i in inventory.size():
		if inventory[i] == item_data_clicked_from_signal:
			if current_item_index != i:
				current_item_index = i
				update_ui_elements()
			elif not is_combine_mode:
				_on_use_equip_button_pressed()
			break

func _on_use_equip_button_pressed():
	if is_combine_mode:
		cancel_combination_mode()
		return
	if inventory.is_empty() or current_item_index < 0:
		return
	
	var item_instance = inventory[current_item_index]
	var item_id = item_instance.id
	var item_type = item_instance.type

	if item_type == "weapon":
		if equipped_item_id == item_id:
			unequip_current_item()
		else:
			equip_item(item_instance)
	elif item_type == "consumable":
		if item_instance.has("heal_amount"):
			heal(item_instance.heal_amount)
		remove_item_from_inventory(item_id, 1)
	elif item_type == "puzzle":
		var player = get_parent()
		if player and player.has_method("use_puzzle_item"):
			player.use_puzzle_item(item_id)
	
	update_ui_elements()


func equip_item(item: Dictionary):
	equipped_item_id = item.id
	#print("Equipado: ", item.name)
	update_ui_elements()

func get_equipped_item():
	return equipped_item_id

func unequip_current_item():
	if equipped_item_id:
		var item = get_inventory_item_by_id(equipped_item_id) 
		#print("Desequipado: ", item.get("name", "Item Desconhecido"))
		equipped_item_id = null
	update_ui_elements()

func update_use_equip_button_text_and_state():
	if is_combine_mode:
		use_equip_button.text = "Cancelar"
		use_equip_button.disabled = false
		return
	if inventory.is_empty() or current_item_index < 0:
		use_equip_button.text = "Usar/Equipar"
		use_equip_button.disabled = true
		return
	
	var item = inventory[current_item_index]
	if item.id == equipped_item_id and item.type == "weapon":
		use_equip_button.text = "Desequipar"
		use_equip_button.disabled = false
	elif item.type == "weapon":
		use_equip_button.text = "Equipar"
		use_equip_button.disabled = false
	elif item.type == "consumable":
		use_equip_button.text = "Usar"
		use_equip_button.disabled = false
	elif item.type == "puzzle":
		use_equip_button.text = "Usar"
		use_equip_button.disabled = false
	else:
		use_equip_button.text = "---"
		use_equip_button.disabled = true

func update_equipped_item_display():
	if equipped_item_id:
		var item_instance = get_inventory_item_by_id(equipped_item_id)
		var display_text = "Equipado: " + item_instance.get("name", "N/A")
		if item_instance.has("current_ammo"):
			display_text += " (%d/%d)" % [item_instance.current_ammo, item_instance.max_ammo]
		equipped_item_label.text = display_text
	else:
		equipped_item_label.text = "Equipado: Nenhum"


func _get_combination_result_id(id1, id2):
	if (id1 == "green_herb" and id2 == "green_herb"):
		return "green_herb_plus"
	if (id1 == "green_herb_plus" and id2 == "green_herb") or (id1 == "green_herb" and id2 == "green_herb_plus"):
		return "green_herb_plus_plus"
	if (id1 == "green_herb" and id2 == "red_herb") or (id1 == "red_herb" and id2 == "green_herb"):
		return "herb_mix"
	return ""

func is_reload_combination(id1, id2):
	return (id1 == "revolver" and id2 == "revolver_ammo") or (id1 == "revolver_ammo" and id2 == "revolver")

func can_items_be_combined(item1_id_param, item2_id_param):
	if not ITEM_DATA.has(item1_id_param) or not ITEM_DATA.has(item2_id_param):
		return false
	
	var item1_tpl = ITEM_DATA[item1_id_param]
	var item2_tpl = ITEM_DATA[item2_id_param]

	if not item1_tpl.get("combinable",false) or not item2_tpl.get("combinable",false):
		return false
	
	if is_reload_combination(item1_id_param, item2_id_param):
		var revolver_instance = get_inventory_item_by_id("revolver")
		if revolver_instance.is_empty() or revolver_instance.current_ammo >= revolver_instance.max_ammo:
			return false 
		return get_item_count("revolver_ammo") > 0 
	
	return _get_combination_result_id(item1_id_param, item2_id_param) != ""


func update_combine_button_text_and_state():
	var can_any_item_initiate_combine = false
	for item_instance_in_inv in inventory:
		if item_instance_in_inv.get("combinable", false):
			can_any_item_initiate_combine = true
			break
	
	if not is_combine_mode:
		combine_button.text = "Combinar"
		var current_item_can_initiate = false
		if not inventory.is_empty() and current_item_index != -1:
			current_item_can_initiate = inventory[current_item_index].get("combinable", false)
		combine_button.disabled = not current_item_can_initiate
	else:
		var can_current_selection_form_recipe = false
		if not inventory.is_empty() and current_item_index != -1 and first_item_for_combination.has("id"):
			var current_sel_item_id = inventory[current_item_index].id
			if inventory[current_item_index].get("combinable", false):
				can_current_selection_form_recipe = can_items_be_combined(first_item_for_combination.id, current_sel_item_id)
		combine_button.disabled = not can_current_selection_form_recipe


func _on_combine_button_pressed():
	if not is_combine_mode:
		if inventory.is_empty() or current_item_index < 0:
			return

		var sel_item_instance = inventory[current_item_index]
		if not sel_item_instance.get("combinable", false):
			#print(sel_item_instance.name + " não é combinável.")
			return

		first_item_for_combination = sel_item_instance.duplicate(true)
		first_item_for_combination["original_inventory_index"] = current_item_index
		is_combine_mode = true
		#print("Modo Comb.: " + first_item_for_combination.name + " sel. Escolha 2º item.")
	else:
		if inventory.is_empty() or current_item_index < 0:
			cancel_combination_mode()
			return
		var second_item_instance = inventory[current_item_index] 
		if not first_item_for_combination.has("id"):
			cancel_combination_mode()
			return
		execute_combination(first_item_for_combination, second_item_instance) 
		cancel_combination_mode()
	update_ui_elements()

func cancel_combination_mode():
	is_combine_mode = false
	first_item_for_combination = {}
	#print("Modo de combinação cancelado/finalizado.")
	update_ui_elements()

func execute_combination(item1_data_for_combine: Dictionary, item2_data_for_combine: Dictionary):
	var id1 = item1_data_for_combine.id
	var id2 = item2_data_for_combine.id
	
	if is_reload_combination(id1, id2):
		var revolver_inv_item = get_inventory_item_by_id("revolver")
		
		if revolver_inv_item.current_ammo >= revolver_inv_item.max_ammo:
			#print("Revólver já está cheio.")
			return
		
			
		var bullets_needed = revolver_inv_item.max_ammo - revolver_inv_item.current_ammo
		var bullets_to_transfer = min(get_item_count("revolver_ammo"), bullets_needed)
		
		if bullets_to_transfer > 0:
			revolver_inv_item.current_ammo += bullets_to_transfer
			remove_item_from_inventory("revolver_ammo", bullets_to_transfer)
			#print("Revólver recarregado com %d balas. Munição: %d/%d" % [bullets_to_transfer, revolver_inv_item.current_ammo, revolver_inv_item.max_ammo])
			for i in inventory.size():
				if inventory[i].id == "revolver":
					current_item_index = i
					break
		return

	var result_id = _get_combination_result_id(id1, id2)
	if result_id:
		var qty1_needed = 1
		var qty2_needed = 1
		if id1 == id2:
			qty1_needed = 2
		
		if get_item_count(id1) >= qty1_needed and (id1 == id2 or get_item_count(id2) >= qty2_needed):
			remove_item_from_inventory(id1, 1)
			remove_item_from_inventory(id2, 1)
			add_item_to_inventory(result_id, 1)
			#print("Sucesso! Criado: " + ITEM_DATA[result_id].name)
			var new_item_idx = -1
			for i in inventory.size():
				if inventory[i].id == result_id:
					new_item_idx = i
					break
			if new_item_idx != -1:
				current_item_index = new_item_idx
			
			if equipped_item_id == id1 and get_item_count(id1) == 0:
				unequip_current_item()
			if id1 != id2 and equipped_item_id == id2 and get_item_count(id2) == 0:
				unequip_current_item()
		#else:
			#print("Itens insuficientes para combinar.")
	#else:
		#print("Combinação inválida: " + item1_data_for_combine.name + " e " + item2_data_for_combine.name + ".")


func _on_prev_item_button_pressed(): cycle_inventory(-1)
func _on_next_item_button_pressed(): cycle_inventory(1)

func save_persistent_state() -> Dictionary:
	return {
		"current_health": current_health,
		"current_item_index": current_item_index,
		"equipped_item_id": equipped_item_id,
		"inventory": inventory
	}

func load_persistent_state(data: Dictionary):
	if data.has("current_health"):
		current_health = data["current_health"]
	if data.has("current_item_index"):
		current_item_index = data["current_item_index"]
	if data.has("equipped_item_id"):
		equipped_item_id = data["equipped_item_id"]
	if data.has("inventory"):
		var loaded_inv = data["inventory"]
		if loaded_inv is Array:
			inventory.clear()
			for item in loaded_inv:
				#print(item)
				if item.has("quantity"):
					item["quantity"] = int(item["quantity"])
				inventory.append(item)
	update_ui_elements()

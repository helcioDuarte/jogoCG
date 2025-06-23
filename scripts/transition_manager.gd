extends Node

var transition_layer_scene = preload("res://scenes/transition_layer.tscn")
var is_transitioning = false
var scene_states = {}
var inventoryState = {}
var inventoryPath = ""

func start(scene_path: String):
	if is_transitioning:
		return

	is_transitioning = true
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

	loading_label.visible = false
	radial_blur_node.visible = false
	black_node.visible = true
	
	var error = get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("Failed to load scene: %s" % scene_path)
		instance.queue_free()
		is_transitioning = false
		return

	# Wait two frames to ensure the new scene is fully initialized
	await get_tree().process_frame
	await get_tree().process_frame

	_load_new_scene_state()

	var tween_out = get_tree().create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween_out.tween_property(fade_material, "shader_parameter/progress", 1.0, 0.7)
	await tween_out.finished

	instance.queue_free()
	is_transitioning = false

func _save_current_scene_state():
	var current_scene = get_tree().current_scene
	if current_scene == null or current_scene.scene_file_path.is_empty():
		return
		
	var state = {}
	var persistent = {}
	var savable_nodes = get_tree().get_nodes_in_group("savable")
	for node in savable_nodes:
		if node.has_method("save_state"):
			state[node.get_path()] = node.call("save_state")
		elif node.name == "InventoryPanel":
			inventoryState = node.call("save_persistent_state")
			
	if !state.is_empty():
		scene_states[current_scene.scene_file_path] = state

func _load_new_scene_state():
	var current_scene = get_tree().current_scene
	var inventory_node = current_scene.find_child("InventoryPanel")
	if inventory_node != null:
		inventory_node.call("load_persistent_state", inventoryState)
	if current_scene == null or !scene_states.has(current_scene.scene_file_path):
		return

	var state = scene_states[current_scene.scene_file_path]
	for node_path_str in state:
		var node = current_scene.get_node_or_null(node_path_str)
		if node != null and node.has_method("load_state"):
			node.call("load_state", state[node_path_str])

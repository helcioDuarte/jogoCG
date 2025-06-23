extends Node

var transition_layer_scene = preload("res://scenes/transition_layer.tscn")
var is_transitioning = false

func start(scene_path: String):
	if is_transitioning:
		return

	is_transitioning = true

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
	var dot_count = 1
	
	var tween_in = get_tree().create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween_in.tween_property(radial_blur_material, "shader_parameter/progress", 1.0, 0.7)
	await tween_in.finished

	loading_label.visible = false
	radial_blur_node.visible = false
	black_node.visible = true
	var error = get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("Falha ao carregar a cena: %s" % scene_path)

	var tween_out = get_tree().create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween_out.tween_property(fade_material, "shader_parameter/progress", 1.0, 0.7)
	await tween_out.finished

	instance.queue_free()
	is_transitioning = false

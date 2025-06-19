extends Node

var transition_layer_scene = preload("res://scenes/transition_layer.tscn")
var is_transitioning = false

func start(scene_path: String):
	if is_transitioning:
		return

	is_transitioning = true

	var instance = transition_layer_scene.instantiate()
	get_tree().root.add_child(instance)

	var material = instance.get_node("ColorRect").material
	var tween_in = get_tree().create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# 1. Anima o efeito para cobrir a tela
	tween_in.tween_property(material, "shader_parameter/progress", 1.0, 0.7)
	await tween_in.finished

	# 2. Muda a cena quando a tela está coberta
	var error = get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("Falha ao carregar a cena: %s" % scene_path)

	# A camada de transição (`instance`) continua existindo porque é filha da raiz da árvore de cenas.

	var tween_out = get_tree().create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# 3. Anima o efeito para revelar a nova cena
	tween_out.tween_property(material, "shader_parameter/progress", 0.0, 0.7)
	await tween_out.finished

	# 4. Remove a camada de transição e reseta o estado
	instance.queue_free()
	is_transitioning = false

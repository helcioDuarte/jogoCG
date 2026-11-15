# PauseMenu.gd
extends Control


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# Conecte o sinal 'pressed' do seu botão de Salvar a esta função.
func _on_new_game_button_pressed():
	TransitionManager.reset_state()
	$AcceptEffect.play()
	$VBoxContainer.visible = false
	$VideoStreamPlayer.visible = true
	$VideoStreamPlayer.play()
# Conecte o sinal 'pressed' do seu botão de Carregar a esta função.
func _on_load_button_pressed():
	$AcceptEffect.play()
	if TransitionManager.load_game():
		TransitionManager.start(TransitionManager.get_saved_scene())
	# O menu será fechado automaticamente quando a cena for trocada.

func _on_exit_button_pressed():
	get_tree().quit()


func videoFinished() -> void:
	TransitionManager.start("res://scenes/overworld.tscn")
	
	
func pause_game():
	get_tree().paused = true
	if not is_visible():
		$background.texture = ImageTexture.create_from_image(get_viewport().get_texture().get_image())
	visible = true

func unpause_game():
	get_tree().paused = false
	visible = false

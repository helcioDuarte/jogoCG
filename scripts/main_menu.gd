# PauseMenu.gd
extends Control


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# Conecte o sinal 'pressed' do seu botão de Salvar a esta função.
func _on_new_game_button_pressed():
	$AcceptEffect.play()
	TransitionManager.start("res://scenes/overworld.tscn")
# Conecte o sinal 'pressed' do seu botão de Carregar a esta função.
func _on_load_button_pressed():
	$AcceptEffect.play()
	TransitionManager.load_game()
	TransitionManager.start("res://scenes/banheiro.tscn")
	# O menu será fechado automaticamente quando a cena for trocada.

func _on_exit_button_pressed():
	get_tree().quit()

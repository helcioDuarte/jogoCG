# PauseMenu.gd
extends Control

# Referências para os nós da interface. Ajuste os caminhos se sua cena for diferente.
@onready var confirmation_label = $Panel/VBoxContainer/ConfirmationLabel
@onready var confirmation_timer = $Timer

func _ready():
	confirmation_label.hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# Conecte o sinal 'pressed' do seu botão de Salvar a esta função.
func _on_save_button_pressed():
	TransitionManager.save_game()
	confirmation_label.text = "Jogo Salvo!"
	confirmation_label.show()
	confirmation_timer.start()

# Conecte o sinal 'pressed' do seu botão de Carregar a esta função.
func _on_load_button_pressed():
	TransitionManager.load_game()
	TransitionManager.start("res://scenes/banheiro.tscn")
	# O menu será fechado automaticamente quando a cena for trocada.

# Conecte o sinal 'timeout' do seu Timer a esta função.
func _on_confirmation_timer_timeout():
	confirmation_label.hide()


func _on_exit_button_pressed() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	TransitionManager.start("res://scenes/banheiro.tscn")

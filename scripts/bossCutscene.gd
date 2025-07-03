extends Control

# Conecte o sinal 'pressed' do seu botão de Salvar a esta função.
func _ready():
	$VideoStreamPlayer.visible = true
	$VideoStreamPlayer.play()

func videoFinished() -> void:
	$"../Node3D".position.x = 45.886
	$"../Node3D".position.y = 0.044
	$"../Node3D".position.z = -1.318
	

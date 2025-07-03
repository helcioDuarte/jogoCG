extends Area3D

func _ready():
	# Apenas para ter certeza, definimos a máscara aqui também.
	self.collision_mask = 1 
	print("--- ÁREA DE TESTE PRONTA --- Máscara: ", self.collision_mask)

	# Conectamos os sinais para imprimir mensagens de forma direta.
	body_entered.connect(func(body): print("!!!! SUCESSO: Corpo ENTROU na área de teste!!!! -> ", body.name))
	body_exited.connect(func(body): print("!!!! SUCESSO: Corpo SAIU da área de teste!!!! -> ", body.name))

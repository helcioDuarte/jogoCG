extends PathFollow3D

@onready var animation_player = $AnimacaoDoCaminho
@onready var inimigo = $Mumble

func _ready():
	animation_player.play("AnimaçãoDoCaminho")

func _process(_delta):
	if is_instance_valid(inimigo) and inimigo.estado == inimigo.Estado.PATRULHANDO:
		var forward = -global_transform.basis.z.normalized()
		inimigo.look_at(global_position + forward, Vector3.UP)

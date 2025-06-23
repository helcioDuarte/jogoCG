extends MeshInstance3D

@export var destination = "res://scenes/sala.tscn"
var player = null
var canEnter = false

func enter(body):
	if body.name == "player":
		player = player if player != null else body
		canEnter = true

func leave(body):
	if body.name == "player":
		canEnter = false

func _process(_delta: float) -> void:
	if !canEnter:
		return
	
	if Input.is_action_just_pressed("interact"):
		TransitionManager.start(destination)

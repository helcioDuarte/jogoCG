extends MeshInstance3D

@export var destination = "res://scenes/sala.tscn"
@export var room = "overworld"
@export var open = true
@export var message: Array[String] = ["Trancado..."]
var player = null
var canEnter = false
var openBuffer = 0

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
		if open:
			TransitionManager.setRoom(room)
			TransitionManager.start(destination)
		elif openBuffer > 0: # só tenta abrir a porta de novo após fechar o diálogo
			openBuffer -= 1
		else:
			openBuffer = message.size()
			$textBox.start_dialogue(message)
			
func save_state() -> Dictionary:
	return {
		"open": open
	}

func load_state(data: Dictionary):
	if data.has("has_been_triggered"):
		open = data["open"]

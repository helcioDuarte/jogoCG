extends MeshInstance3D

@onready var outline = find_child("MeshInstance3D")
@onready var text = $"../../../textBox/Area3D"
var first = true
var player = null
var canClose = false

func _ready():
	outline.visible = false

func createTrigger():
	var trigger = CollisionShape3D.new()
	trigger.shape = BoxShape3D.new()
	trigger.shape.size.x = 1.803
	trigger.shape.size.z = 1.928
	trigger.position.x = 0.024
	trigger.position.z = -0.464
	text.add_child(trigger)

func enter(body):
	if body.name == "player":
		player = player if player != null else body
		outline.visible = true

func leave(body):
	if body.name == "player":
		outline.visible = false

func _process(_delta: float) -> void:
	var gossip = $"../../../gossip"
	
	if !outline.visible:
		gossip.visible = false
		return
	
	if Input.is_action_just_pressed("interact"):
		gossip.visible = !gossip.visible
		$"../../../gossip/Timer".start()
		canClose = false
		if first:
			createTrigger()
			first = false
	elif Input.is_anything_pressed() and canClose:
		gossip.visible = false

func timerEnd():
	canClose = true

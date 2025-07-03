extends Area3D


@onready var outline = get_parent().find_child("MeshInstance3D")
var player = null
var dead = false
func _ready():
	outline.visible = false
	outline.material_overlay = load("res://textures/outline.tres")

func enter(body):
	if not get_parent().visible:
		return

	if body.name == "player":
		player = player if player != null else body
		outline.visible = true

func leave(body):
	if body.name == "player":
		outline.visible = false

func _process(_delta: float) -> void:
	if !outline.visible or dead:
		return
	
	if Input.is_action_just_pressed("interact"):
		player.inventory.add_item_to_inventory(get_parent().name, 1)
		dead = true
		get_parent().visible = false
		
func save_state() -> Dictionary:
	return {
		"dead": dead
	}

func load_state(data: Dictionary):
	if data.has("dead"):
		dead = data["dead"]
		if dead:
			get_parent().visible = false

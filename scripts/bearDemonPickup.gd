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
	
	if Input.is_action_just_pressed("interact") and player.inventory.get_inventory_item_by_id("revolver") != {}:
		$"../CanvasLayer".visible = true
		var tween = create_tween()
		tween.tween_property($"../CanvasLayer/ColorRect".material, "shader_parameter/flash_alpha", 1.0, 0.1)
		tween.tween_property($"../CanvasLayer/ColorRect".material, "shader_parameter/flash_alpha", 0.0, 0.4)
		player.pewpewpew()
		$"../../../caixas de texto/textBox2/Area3D".position.y = 3.599
		$"../../yellow_bear".position.y = 0
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

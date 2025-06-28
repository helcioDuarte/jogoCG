extends Camera3D

@onready var player = get_node($"../../../player".get_path())
@onready var r0 = Vector3(global_rotation.x, global_rotation.y, global_rotation.z)
const follow_speed = 0.1
var activated = true

func set_camera():
	look_at(player.global_position, Vector3.UP)
	activated = true
	current = true

func _process(delta):
	if current and is_instance_valid(player):
		look_at(player.global_position, Vector3.UP)

	if !current and activated:
		global_rotation = r0

func save_state() -> Dictionary:
	return {
		"rotation": rotation,
		"activated": activated,
		"current": current
	}

func load_state(data: Dictionary):
	if data.has("rotation"):
		if data["rotation"] is String: # se o jogo é carregado os valores viram string por algum motivo
			data["rotation"] = data["rotation"].replace("(", "").replace(")", "").split(", ") # nojento
			rotation.x = float(data["rotation"][0])
			rotation.y = float(data["rotation"][1])
			rotation.z = float(data["rotation"][2])
		else:
			rotation = data["rotation"]
	if data.has("activated"):
		activated = data["activated"]
	if data.has("current"):
		current = data["current"]

extends Camera3D

var activated = false

func set_camera():
	activated = true
	current = true

func save_state() -> Dictionary:
	return {
		"activated": activated,
		"current": current
	}

func load_state(data: Dictionary):
	if data.has("activated"):
		activated = data["activated"]
	if data.has("current"):
		current = data["current"]

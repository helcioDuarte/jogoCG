extends Area3D

@export var messages: Array[String]
var textBox = null


var has_been_triggered = false

func _ready():
	add_to_group("savable")
	textBox = get_parent()
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if has_been_triggered:
		return
	if not (body.is_in_group("player") or body.name == "player"):
		return
		
	has_been_triggered = true
	textBox.start_dialogue(messages.duplicate(), body)

func setTrigger(b):
	has_been_triggered = b

func save_state() -> Dictionary:
	return {
		"has_been_triggered": has_been_triggered
	}

func load_state(data: Dictionary):
	if data.has("has_been_triggered"):
		has_been_triggered = data["has_been_triggered"]

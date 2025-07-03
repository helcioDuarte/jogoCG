extends Control

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass
	

func _on_load_pressed() -> void:
	$VBoxContainer/Click.play()
	
func _on_exit_pressed() -> void:
	$VBoxContainer/Click.play()

func _on_new_pressed() -> void:
	$VBoxContainer/Click.play() # Replace with function body.

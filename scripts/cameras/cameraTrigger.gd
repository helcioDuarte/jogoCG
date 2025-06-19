extends Area3D

var inside = false

func enter(body):
	if body.name == "player":
		inside = true

func leave(body):
	if body.name == "player":
		inside = false
		
func _process(_delta: float) -> void:
	if inside && get_parent().current != true:
		get_parent().set_camera() # change the camera
		$"../../../../player".switch_camera() # update camera on player

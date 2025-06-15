extends Area3D

@onready var player = $".."
var stairs = 0
var not_stairs = 0

func enter_area_not(body):
	if body is not StaticBody3D:
		return
	not_stairs += 1

func exit_area_not(body):
	if body is not StaticBody3D:
		return
	not_stairs -= 1

func enter(body):
	if body is not StaticBody3D:
		return
	stairs += 1

func leave(body):
	if body is not StaticBody3D:
		return
	stairs -= 1
	
func should_step_up():
	print("good ", stairs, " | bad ", not_stairs)
	return stairs > not_stairs

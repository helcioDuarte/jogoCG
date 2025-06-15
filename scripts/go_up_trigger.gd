extends Area3D

@onready var player = $".."
@export var stepHeight = 1
var stairs = 0

func enter(body):
	if body is not StaticBody3D:
		print(body, " is not good")
	else:
		print(body, " is good")
	print(body.global_position.y, " ", player.global_position.y)
	#if abs(body.global_position.y - player.global_position.y) < stepHeight:
		#stairs += 1

func leave(body):
	if body is not StaticBody3D:
		return
	if abs(body.global_position.y - player.global_position.y) < stepHeight:
		stairs -= 1

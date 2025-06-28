@tool
extends Camera3D

@export var target: Node3D = null
@export var distance: float = 5.0
@export var speed: float = 0.5
@export var height_offset: float = 2.0

var angle: float = 0.0

func _process(delta: float):
	if not target:
		return

	angle += speed * delta

	var offset = Vector3(sin(angle), 0, cos(angle)) * distance
	var target_pos = target.global_position + Vector3(0, height_offset, 0)

	global_position = target_pos + offset
	look_at(target_pos)

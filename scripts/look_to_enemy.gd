extends Area3D

var enemies_in_range = []

func _on_body_entered(body: Node3D) -> void:
	if body.name == "player":
		return
	if body is CharacterBody3D:
		enemies_in_range.append(body)
		print(enemies_in_range)


func _on_body_exited(body: Node3D) -> void:
	if body.name == "player":
		return
	if body is CharacterBody3D:
		enemies_in_range.erase(body)

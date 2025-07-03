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

func get_enemy():
	if enemies_in_range.is_empty():
		return null

	var closest_enemy = null
	var closest_distance_sq = INF

	var player_position = get_parent().global_transform.origin

	for enemy in enemies_in_range:
		if is_instance_valid(enemy):
			var distance_sq = player_position.distance_squared_to(enemy.global_transform.origin)
			if distance_sq < closest_distance_sq:
				closest_distance_sq = distance_sq
				closest_enemy = enemy
	return closest_enemy

extends Area3D

@export var puzzle_manager_node: Node
@onready var bear_spawn_point = $BearSpawnPoint

var current_bear_id: String = ""
var player_ref = null

const BEAR_SCENES = {
	"red_bear": preload("res://scenes/puzzles/red_bear.tscn"),
	"blue_bear": preload("res://scenes/puzzles/blue_bear.tscn"),
	"green_bear": preload("res://scenes/puzzles/green_bear.tscn"),
	"yellow_bear": preload("res://scenes/puzzles/yellow_bear.tscn"),
	"black_bear": preload("res://scenes/puzzles/black_bear.tscn"),
}

func hide_bear_and_disable():
	# Apaga qualquer modelo de urso que esteja dentro do spawn point.
	for child in bear_spawn_point.get_children():
		child.queue_free()
	
	# Desativa a forma de colisão para impedir futuras interações.
	# Assumindo que sua CollisionShape3D é uma filha direta desta Area3D.
	var collision_shape = find_child("CollisionShape3D")
	if is_instance_valid(collision_shape):
		collision_shape.disabled = true

func _ready():
	pass

func _on_body_entered(body):
	if body.name == "player":
		player_ref = body
		body.register_placeholder(self)

func _on_body_exited(body):
	if body.name == "player":
		player_ref = null
		body.unregister_placeholder(self)

func place_bear(bear_id: String):
	if current_bear_id != "":
		return

	current_bear_id = bear_id
	if BEAR_SCENES.has(bear_id):
		var bear_instance = BEAR_SCENES[bear_id].instantiate()
		bear_spawn_point.add_child(bear_instance)
	
	if puzzle_manager_node:
		puzzle_manager_node.update_puzzle_state(self, current_bear_id)

func pickup_bear() -> String:
	if current_bear_id == "":
		return ""

	var picked_bear_id = current_bear_id
	current_bear_id = ""
	
	for child in bear_spawn_point.get_children():
		child.queue_free()

	if puzzle_manager_node:
		puzzle_manager_node.update_puzzle_state(self, "")
		
	return picked_bear_id

func set_initial_bear(bear_id: String):
	if bear_id == "":
		return

	current_bear_id = bear_id
	if BEAR_SCENES.has(bear_id):
		var bear_instance = BEAR_SCENES[bear_id].instantiate()
		bear_spawn_point.add_child(bear_instance)

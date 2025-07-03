extends Node

@export var correct_sequence: Array[String] = ["blue_bear", "yellow_bear", "black_bear", "green_bear", "red_bear"]
@export var placeholders: Array[NodePath]
@export var key_item_path: NodePath

var current_state: Dictionary = {}
var is_solved = false

func _ready():
	for p_path in placeholders:
		var placeholder_node = get_node(p_path)
		if is_instance_valid(placeholder_node):
			current_state[placeholder_node] = ""
	
	setup_initial_state()

func setup_initial_state():
	var correct_placeholder_path = placeholders[0]
	var correct_bear_id = correct_sequence[0]
	var correct_node = get_node(correct_placeholder_path)
	if is_instance_valid(correct_node):
		correct_node.set_initial_bear(correct_bear_id)
		update_puzzle_state(correct_node, correct_bear_id)
	
	var wrong_placeholder_path = placeholders[4]
	var wrong_bear_id = "green_bear"
	var wrong_node = get_node(wrong_placeholder_path)
	if is_instance_valid(wrong_node):
		wrong_node.set_initial_bear(wrong_bear_id)
		update_puzzle_state(wrong_node, wrong_bear_id)

func update_puzzle_state(placeholder_node: Node, bear_id: String):
	if is_solved or not is_instance_valid(placeholder_node):
		return
		
	current_state[placeholder_node] = bear_id
	print("Estado atual do puzzle: ", current_state)
	check_solution()

func check_solution():
	for i in range(placeholders.size()):
		var p_path = placeholders[i]
		var required_bear = correct_sequence[i]
		var placeholder_node = get_node(p_path)

		if not is_instance_valid(placeholder_node):
			continue

		if not current_state.has(placeholder_node) or current_state[placeholder_node] != required_bear:
			return

	is_solved = true
	print("!!!!!!!! PUZZLE RESOLVIDO !!!!!!!!")
	
	if key_item_path:
		var key_node = get_node(key_item_path)
		if is_instance_valid(key_node):
			key_node.visible = true

	print("Removendo os ursos do puzzle.")
	call_deferred("finalize_puzzle_pieces")

func finalize_puzzle_pieces():
	for p_path in placeholders:
		var placeholder_node = get_node(p_path)
		if is_instance_valid(placeholder_node):
			placeholder_node.hide_bear_and_disable()

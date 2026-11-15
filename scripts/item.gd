extends Area3D


@export var item_id: String = ""

@onready var outline = get_parent().find_child("MeshInstance3D")
var player = null
var dead = false
var _player_in_range = false
var _was_paused = false

const SCENE_NAME_TO_ITEM_ID = {
	"GreenHerb": "green_herb",
	"RedHerb": "red_herb",
	"MedKit": "medkit",
	"Munição": "revolver_ammo"
}

const SCENE_PATH_TO_ITEM_ID = {
	"res://scenes/itens/green_herb.tscn": "green_herb",
	"res://scenes/itens/red_herb.tscn": "red_herb",
	"res://scenes/itens/med_kit.tscn": "medkit",
	"res://scenes/itens/munição.tscn": "revolver_ammo",
	"res://scenes/puzzles/red_bear.tscn": "red_bear",
	"res://scenes/puzzles/blue_bear.tscn": "blue_bear",
	"res://scenes/puzzles/green_bear.tscn": "green_bear",
	"res://scenes/puzzles/yellow_bear.tscn": "yellow_bear",
	"res://scenes/puzzles/black_bear.tscn": "black_bear",
	"res://scenes/puzzles/chave_bandejao.tscn": "chave_bandejao"
}

func _ready():
	add_to_group("savable")
	if outline:
		outline.visible = false
		outline.material_overlay = load("res://textures/outline.tres")

func _resolve_item_id() -> String:
	if not item_id.is_empty():
		return item_id
	var parent = get_parent()
	if parent == null:
		return ""
	if SCENE_NAME_TO_ITEM_ID.has(parent.name):
		return SCENE_NAME_TO_ITEM_ID[parent.name]
	if SCENE_PATH_TO_ITEM_ID.has(parent.scene_file_path):
		return SCENE_PATH_TO_ITEM_ID[parent.scene_file_path]
	return parent.name

func _disable_pickup():
	if outline:
		outline.visible = false
	get_parent().visible = false
	_player_in_range = false
	set_deferred("monitoring", false)
	var col = get_node_or_null("area")
	if col == null:
		col = find_child("CollisionShape3D", false, false)
	if col:
		col.set_deferred("disabled", true)

func enter(body):
	if dead or not get_parent().visible:
		return

	if body.is_in_group("player") or body.name == "player":
		player = player if player != null else body
		_player_in_range = true
		if outline:
			outline.visible = true

func leave(body):
	if body.is_in_group("player") or body.name == "player":
		_player_in_range = false
		if outline:
			outline.visible = false

func _process(_delta: float) -> void:
	if get_tree().paused:
		_was_paused = true
		return
	if _was_paused:
		_was_paused = false
		return
	if dead or not _player_in_range or not get_parent().visible:
		return
	if not is_instance_valid(player):
		return
	
	if Input.is_action_just_pressed("interact"):
		player.inventory.add_item_to_inventory(_resolve_item_id(), 1)
		dead = true
		_disable_pickup()
		
func save_state() -> Dictionary:
	return {
		"dead": dead
	}

func load_state(data: Dictionary):
	if data.has("dead"):
		dead = data["dead"]
		if dead:
			_disable_pickup()

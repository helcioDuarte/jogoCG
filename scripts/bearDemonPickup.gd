extends Area3D


@onready var outline = get_parent().find_child("MeshInstance3D")
var player = null
var dead = false
var _player_in_range = false
var _was_paused = false

func _ready():
	add_to_group("savable")
	if outline:
		outline.visible = false
		outline.material_overlay = load("res://textures/outline.tres")

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
	
	if Input.is_action_just_pressed("interact") and player.inventory.get_inventory_item_by_id("revolver") != {}:
		var canvas_layer = get_node_or_null("../CanvasLayer")
		if canvas_layer:
			canvas_layer.visible = true
			var flash_rect = get_node_or_null("../CanvasLayer/ColorRect")
			if flash_rect and flash_rect.material:
				var tween = create_tween()
				tween.tween_property(flash_rect.material, "shader_parameter/flash_alpha", 1.0, 0.1)
				tween.tween_property(flash_rect.material, "shader_parameter/flash_alpha", 0.0, 0.4)
		player.pewpewpew()
		var text_area = get_node_or_null("../../../caixas de texto/textBox2/Area3D")
		if text_area:
			text_area.position.y = 3.599
		var yellow_bear = get_node_or_null("../../yellow_bear")
		if yellow_bear:
			yellow_bear.position.y = 0
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
			var text_area = get_node_or_null("../../../caixas de texto/textBox2/Area3D")
			if text_area:
				text_area.position.y = 3.599
			var yellow_bear = get_node_or_null("../../yellow_bear")
			if yellow_bear:
				yellow_bear.position.y = 0

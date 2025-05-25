extends PanelContainer

signal item_clicked(item_data)

var item_data: Dictionary

const NORMAL_MODULATE = Color(1,1,1,1)
const SELECTED_MODULATE = Color(1.2, 1.2, 0.8, 1) # Yellowish
const COMBINE_SOURCE_MODULATE = Color(0.8, 1.2, 0.8, 1) # Greenish

func _on_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		emit_signal("item_clicked", item_data)
		get_viewport().set_input_as_handled()

func set_item(data: Dictionary):
	item_data = data
	var icon_texture = load(item_data.get("icon_path", "res://icon.svg"))
	%TextureRect.texture = icon_texture

	if item_data.has("quantity"):
		%QuantityLabel.text = "x" + str(item_data.get("quantity", 1))
		%QuantityLabel.visible = true
	else:
		%QuantityLabel.text = ""
	
	modulate = NORMAL_MODULATE

func set_highlight_mode(mode: String):
	match mode:
		"selected":
			modulate = SELECTED_MODULATE
		"combine_source":
			modulate = COMBINE_SOURCE_MODULATE
		_: # default
			modulate = NORMAL_MODULATE

func select_item():
	set_highlight_mode("selected")

func deselect_item():
	set_highlight_mode("normal")

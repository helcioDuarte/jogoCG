extends CanvasLayer

@onready var label = $PanelContainer/MarginContainer/Label
@onready var timer = $Timer

var text_queue = []
var is_displaying = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	timer.timeout.connect(_on_timer_timeout)

func _unhandled_input(event):
	if event.is_action_pressed("ui_accept") and is_displaying:
		if label.visible_ratio < 1.0:
			label.visible_ratio = 1.0
			timer.stop()
		else:
			_display_next_message()

func start_dialogue(messages):
	$background.texture = ImageTexture.create_from_image(get_viewport().get_texture().get_image())
	text_queue = messages
	_display_next_message()

func _display_next_message():
	if text_queue.size() > 0:
		get_tree().paused = true
		is_displaying = true
		show()
		label.text = text_queue.pop_front()
		label.visible_ratio = 0.0
		timer.start()
	else:
		get_tree().paused = false
		is_displaying = false
		hide()

func _on_timer_timeout():
	if label.visible_ratio < 1.0:
		label.visible_ratio += 0.05
	else:
		timer.stop()

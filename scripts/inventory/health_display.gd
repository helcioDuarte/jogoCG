extends Control

@onready var line_2d: Line2D = %HeartbeatLine

var time = 0.0
var pulse_speed = 0.5
var pulse_amplitude = 25.0
var line_length = 100.0
var base_y = 50.0
var color = Color.WHITE
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	%Portrait.texture = load("res://textures/else_duarte.png")
	line_2d.width = 2.5
	line_2d.antialiased = true
	line_2d.position.x -= 3
	custom_minimum_size = Vector2(line_length + 20, base_y + pulse_amplitude + 20)

func _process(delta):
	time += delta * pulse_speed
	line_2d.default_color = color * 0.5
	%Background.color = color
	_draw_heartbeat()

func _draw_heartbeat():
	line_2d.clear_points()
	var control_width = size.x if size.x > 0 else line_length + 20
	var actual_line_length = control_width - 14
	var num_points = 150
	var wave_frequency = 1.0

	for i in range(num_points + 1):
		var x_progress = float(i) / num_points
		var x = 10 + x_progress * actual_line_length
		var cycle_x = fmod(x_progress * wave_frequency - time, 1.0)

		if cycle_x < 0.0:
			cycle_x += 1.0

		var y_offset_factor = 0.0

		if cycle_x < 0.05:
			y_offset_factor = cycle_x / 0.05 * -0.1
		elif cycle_x < 0.1:
			y_offset_factor = -0.1 + ((cycle_x - 0.05) / 0.05) * -0.15
		elif cycle_x < 0.2:
			y_offset_factor = -0.25 + ((cycle_x - 0.1) / 0.1) * 1.25
		elif cycle_x < 0.3:
			y_offset_factor = 1.0 - ((cycle_x - 0.2) / 0.1) * 1.4
		elif cycle_x < 0.6:
			var t_progress = (cycle_x - 0.3) / 0.3
			y_offset_factor = -0.4 + sin(t_progress * PI) * 0.6
		else:
			y_offset_factor = 0.0

		var y_offset = y_offset_factor * pulse_amplitude
		var y = base_y - y_offset
		line_2d.add_point(Vector2(x, y))

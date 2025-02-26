extends Control

@onready var pilot_name = $"Timing Box/Name"

@onready var lap = $"Timing Box/Lap"

@onready var gate = $"Timing Box/Gate"

@onready var delta = $"Timing Box/Delta"

@onready var progress_bar = $"ProgressBar"

@onready var burst = $"Timing Box/finish_celebration"

@onready var first_burst = $"Timing Box/first_place_celebration"

@onready var lap1_wittness = $"Lap 1 Wittness"

@onready var lap2_wittness = $"Lap 2 Wittness"

@onready var portrait = $PilotImage

@onready var highlighter = $Highlighter

@onready var crashtimer = $CrashTimer

@onready var crashblinker = $CrashBlinker

var bursted = false

var first_bursted = false

var color_out = "#"

var user_id = 0

var reg_font = load("res://ChakraPetch-Regular.ttf")

var bold_font = load("res://ChakraPetch-Bold.ttf")

var chasing = false

var crashed = false

var is_blinked = false

var place = "0"

signal clicked_pilot




func _ready():
	var target_node = $"../../../.."
	connect("clicked_pilot", Callable(target_node, "_on_clicked_pilot"))



func set_pilot_name(p_name, color):
	pilot_name.text = str(p_name)
	pilot_name.modulate = color


func set_lap(lap_num):
	lap.text = str(lap_num)


func set_gate(gate_num):
	if int(gate_num) == 2:
		bursted = false
		first_bursted = false
	gate.text = str(gate_num)
	
	#this checks for crashes and times them
	crashed = false
	crashblinker.stop()
	if bursted:
		crashtimer.stop()
	else:
		crashtimer.start()
	delta.modulate = Color(Color.WHITE)


func set_delta(delta_time):
	if delta_time > 0:
		delta.remove_theme_font_override("font")
	elif delta_time >= -.15:
		delta.add_theme_font_override("font", bold_font)
	else:
		delta.remove_theme_font_override("font")
	delta.text = str(delta_time)
	
	
func get_delta():
	return float(delta.text)


func set_progress(prog_value, color):
	progress_bar.value = prog_value
	progress_bar.modulate = color


func set_progress_range(min, max):
	progress_bar.min_value = min
	progress_bar.max_value = max


func toggle_wittness(is_on):
	if is_on:
		lap1_wittness.visible = false
		lap2_wittness.visible = false
	else:
		lap1_wittness.visible = false
		lap2_wittness.visible = false


func trigger_burst():
	if bursted:
		return
	else:
		burst.burst()
		bursted = true


func first_place_burst():
	if first_bursted:
		return
	else:
		first_burst.burst()
		first_bursted = true


func get_pilot_name():
	return pilot_name.text


func get_pilot_time():
	return delta.text


func get_hex_color():
	return color_out


func set_hex_color(hex_color):
	color_out = hex_color


func set_user_id(uid):
	user_id = int(uid)


func get_user_id():
	return user_id


func set_portrait(image):
	portrait.texture = image


func spectating(is_spectating):
	highlighter.visible = is_spectating


func chase_check(color):
	if place <= 7:
		if color_out == "#"+color:
			chasing = false
		else:
			chasing = true


func get_chase():
	return chasing


func reset():
	pilot_name.text = "--"
	pilot_name.modulate = Color(Color.WHITE)
	lap.text = "--"
	gate.text = "--"
	delta.text = "--"
	progress_bar.value = 0
	progress_bar.modulate = Color(Color.WHITE)
	bursted = false
	user_id = 0
	chasing = false
	crashed = false
	is_blinked = false
	crashtimer.stop()
	crashblinker.stop()
	delta.modulate= Color(Color.WHITE)


func _on_crash_timer_timeout():
	if bursted:
		crashblinker.stop()
	else:
		crashed = true
		crashblinker.start()	
	

func _on_crash_blinker_timeout():
	if bursted:
		delta.modulate= Color(Color.WHITE)
		is_blinked = false
		crashblinker.stop()
	if is_blinked:
		delta.modulate= Color(Color.WHITE)
		is_blinked = false
	else:
		delta.modulate= Color(Color.RED)
		is_blinked = true


func set_place(position):
	place = int(position)
	
	
func get_place():
	return position


func _on_gui_input(event):
	if event is InputEventMouseButton:
		emit_signal("clicked_pilot", user_id)
		accept_event()

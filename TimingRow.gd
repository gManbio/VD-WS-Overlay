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

var bursted = false

var first_bursted = false

var color_out = "#"

var user_id = 0

func _ready():
	pass


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


func set_delta(delta_time):
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
		lap1_wittness.visible = true
		lap2_wittness.visible = true
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

extends Control

@onready var pilot_name = $"Timing Box/Name"

@onready var lap = $"Timing Box/Lap"

@onready var gate = $"Timing Box/Gate"

@onready var delta = $"Timing Box/Delta"

@onready var progress_bar = $"ProgressBar"

@onready var burst = $"Timing Box/Orb"

var bursted = false

func _ready():
	pass


func set_pilot_name(p_name, color):
	pilot_name.text = str(p_name)
	pilot_name.modulate = color


func set_lap(lap_num):
	lap.text = str(lap_num)


func set_gate(gate_num):
	gate.text = str(gate_num)


func set_delta(delta_time):
	delta.text = str(delta_time)


func set_progress(prog_value, color):
	progress_bar.value = prog_value
	progress_bar.modulate = color


func set_progress_range(min, max):
	progress_bar.min_value = min
	progress_bar.max_value = max


func trigger_burst():
	burst.burst()
	bursted = true


func reset():
	pilot_name.text = "--"
	pilot_name.modulate = Color(Color.WHITE)
	lap.text = "--"
	gate.text = "--"
	delta.text = "--"
	progress_bar.value = 0
	progress_bar.modulate = Color(Color.WHITE)
	bursted = false

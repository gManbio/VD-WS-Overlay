extends Control

@onready var row_name = $"Timing Box/Name"

@onready var s1 = $"Timing Box/s1"

@onready var s2 = $"Timing Box/s2"

@onready var s3 = $"Timing Box/s3"

@onready var total = $"Timing Box/Total"

var s1_time

var s2_time

var s3_time

func _ready():
	pass


func set_row_name(input_name):
	row_name.text = str(input_name)


func set_s1(sector_time):
	if s1.text == "---":
		s1.text = str(sector_time)
		s1_time = sector_time
		return true
	elif sector_time < float(s1.text):
		s1.text = str(sector_time)
		s1_time = sector_time
		return true
	return false
	
	
func set_s2(sector_time):

	if s2.text == "---":
		s2.text = str(sector_time)
		s2_time = sector_time
		return true
	elif sector_time < float(s2.text):
		s2.text = str(sector_time)
		s2_time = sector_time
		return true
	return false
	
	
func set_s3(sector_time):
	
	if s3.text == "---":
		s3.text = str(sector_time)
		s3_time = sector_time
		set_total()
		return true
	elif sector_time < float(s3.text):
		s3.text = str(sector_time)
		s3_time = sector_time
		set_total()
		return true
	set_total()
	return false
	
	


func set_total():
	var total_time = s1_time + s2_time + s3_time
	total.text = str(total_time)
	


func reset():
	row_name.text = "---"
	s1.text = "---"
	s1.modulate = Color(1 ,1 ,1)
	s2.text = "---"
	s2.modulate = Color(1 ,1 ,1)
	s3.text = "---"
	s3.modulate = Color(1 ,1 ,1)
	total.text = "---"

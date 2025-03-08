extends Control
@onready var score = $Score
@onready var logo = $Logo
@onready var gates = $Gates


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func set_score(input_score):
	score.text = str(input_score)


func get_score():
	return int(score.text)


func set_color(color):
	score.modulate = color
	
	
func reset_scores():
	set_score("-")
	set_color(Color.WHITE)
	set_gates("-")

func update_logo(p1_team):
	pass


func set_gates(input_gates):
	gates.text = str(input_gates)

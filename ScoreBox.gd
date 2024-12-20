extends Control
@onready var score = $Score


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func set_score(input_score):
	score.text = str(input_score)


func set_color(color):
	score.modulate = color
	
	
func reset_scores():
	set_score("-")
	set_color(Color.WHITE)

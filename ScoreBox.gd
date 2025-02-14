extends Control
@onready var score = $Score
@onready var logo = $Logo

var team_logos = {
	"#00FF00": preload("res://Team Logos/533_black.jpg"),
	"#406BFF": preload("res://Team Logos/din_black.jpg"),
	"#00FFFF": preload("res://Team Logos/mav_black.jpg"),
	"#FF0000": preload("res://Team Logos/dmo_black.jpg"),
	"#9F42FF": preload("res://Team Logos/tbs_black.jpg"),
	"#FFA300": preload("res://Team Logos/vd_black.jpg"),
}


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


func update_logo(p1_team):
	if p1_team in team_logos:
		logo.texture = team_logos[p1_team]
	


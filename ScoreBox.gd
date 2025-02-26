extends Control
@onready var score = $Score
@onready var logo = $Logo

var fyf = preload("res://FlyYouFools.bold512.png")

var team_logos = {
	"#00FF00": preload("res://Team Logos/533.jpg"),
	"#406BFF": preload("res://Team Logos/din.jpg"),
	"#00FFFF": preload("res://Team Logos/mav.jpg"),
	"#FF0000": preload("res://Team Logos/dmo.jpg"),
	"#9F42FF": preload("res://Team Logos/tbs.jpg"),
	"#FFA300": preload("res://Team Logos/vd.jpg"),
}

var score_threshold = 10


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func set_score(input_score, position_view, show_negative):
	if position_view:
		var temp_score = input_score - score_threshold
		if temp_score <= 0:
			if show_negative:
				score.text = str(temp_score)
			else:
				score.text = ""
		else:
			score.text = str(temp_score)
	else:
		score.text = str(input_score)


func get_score():
	return int(score.text)


func set_color(color):
	score.modulate = color
	
	
func reset_scores():
	set_score("-", true, false)
	set_color(Color.WHITE)


func update_logo(p1_team):
	if p1_team in team_logos:
		logo.texture = team_logos[p1_team]
	else:
		logo.texture = fyf


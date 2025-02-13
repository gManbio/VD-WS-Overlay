extends HBoxContainer

@onready var logo_1 = $Logo_1
@onready var logo_2 = $Logo_2

var team_logos = {
	"#00FF00": preload("res://Team Logos/533.jpg"),
	"#406BFF": preload("res://Team Logos/din.jpg"),
	"#00FFFF": preload("res://Team Logos/mav.jpg"),
	"#FF0000": preload("res://Team Logos/mgp.jpg"),
	"#9F42FF": preload("res://Team Logos/tbs.jpg"),
	"#FFA300": preload("res://Team Logos/vd.jpg"),
}


func update_p1_logo(p1_team):
	if p1_team in team_logos:
		logo_1.texture = team_logos[p1_team]
	
func update_p2_logo(p2_team):
	if p2_team in team_logos:
		logo_2.texture = team_logos[p2_team]

extends Node


func load():
	var file = FileAccess.open("user://save_game.csv", FileAccess.READ)
	var content = file.get_as_text()
	return content


func _ready():
	var file = load()
	for row in file:
		print(row)

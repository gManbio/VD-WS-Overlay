extends Control

var FPS = 10

func _ready():
	Engine.max_fps = FPS

func _on_multi_mode_button_pressed():
	get_tree().change_scene_to_file("res://NewMain.tscn")


func _on_nem_mode_button_pressed():
	get_tree().change_scene_to_file("res://NemesisMode.tscn")


func _on_settings_button_pressed():
	get_tree().change_scene_to_file("res://Settings.tscn")

extends Control

var always_on_top = false
var is_borderless = false


func _on_aot_button_toggled(toggled_on: bool):
	# In Godot 4.0, the main window ID is 0 by default.
	always_on_top = toggled_on

func _on_borderless_button_toggled(toggled_on: bool):
	# In Godot 4.0, the main window ID is 0 by default.
	is_borderless= toggled_on
	

func _on_menu_button_pressed():
	get_tree().change_scene_to_file("res://Menu.tscn")


extends Control


func _on_check_button_toggled(toggled_on: bool):
	# In Godot 4.0, the main window ID is 0 by default.
	var window_id = 0

	print(toggled_on)


func _on_menu_button_pressed():
	get_tree().change_scene_to_file("res://Menu.tscn")

extends VBoxContainer

@onready var name_input = $"Custom Name"
@onready var button = $"Custom Name/Custom Button"
@onready var cam_num = $"Custom Name/Cust@om Button/Custom Cam Num"
@onready var ws_new_main = $"../../.."

signal send_camera

var current_cam = "0"


func _on_custom_name_text_changed(new_text):
	button.text = new_text


func _on_special_1_edit_text_changed(new_text):
	current_cam = new_text


func _on_custom_button_pressed():
	emit_signal("send_camera", current_cam)


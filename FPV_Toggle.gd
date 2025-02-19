extends CheckButton

var fpv_on = false


func _on_toggled(toggled_on):
	fpv_on = toggled_on


func get_fpv():
	return fpv_on

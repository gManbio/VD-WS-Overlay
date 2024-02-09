extends Node

var ws = WebSocketPeer.new()

var heartbeat = ""

var heatData = []
var pilots = []

var name_p1 = ""
var name_p2 = ""
var name_p3 = ""
var name_p4 = ""
var name_p5 = ""
var name_p6 = ""

var gate_p1 = ""
var gate_p2 = ""
var gate_p3 = ""
var gate_p4 = ""
var gate_p5 = ""
var gate_p6 = ""

var delta_p1 = ""
var delta_p2 = ""
var delta_p3 = ""
var delta_p4 = ""
var delta_p5 = ""
var delta_p6 = ""

var slap_p1 = ""
var slap_p2 = ""
var slap_p3 = ""
var slap_p4 = ""
var slap_p5 = ""
var slap_p6 = ""

var prog_p1 = ""
var prog_p2 = ""
var prog_p3 = ""
var prog_p4 = ""
var prog_p5 = ""
var prog_p6 = ""

var p1_list = ""
var p2_list = ""
var p3_list = ""
var p4_list = ""
var p5_list = ""
var p6_list = ""

var display_list = ""

var gate_count = 30

var ip_complete = false

var bg_rect = ""

func _ready():
	
	# var url = "ws://192.168.1.156:60003/velocidrone"
	
	# ws.connect_to_url(url)
	
	$HeartbeatTimer.start()
	
	name_p1 = $"Control/VBoxContainer/Hbox-p1/Name"
	name_p2 = $"Control/VBoxContainer/Hbox-p2/Name"
	name_p3 = $"Control/VBoxContainer/Hbox-p3/Name"
	name_p4 = $"Control/VBoxContainer/Hbox-p4/Name"
	name_p5 = $"Control/VBoxContainer/Hbox-p5/Name"
	name_p6 = $"Control/VBoxContainer/Hbox-p6/Name"
	
	gate_p1 = $"Control/VBoxContainer/Hbox-p1/Gate"
	gate_p2 = $"Control/VBoxContainer/Hbox-p2/Gate"
	gate_p3 = $"Control/VBoxContainer/Hbox-p3/Gate"
	gate_p4 = $"Control/VBoxContainer/Hbox-p4/Gate"
	gate_p5 = $"Control/VBoxContainer/Hbox-p5/Gate"
	gate_p6 = $"Control/VBoxContainer/Hbox-p6/Gate"
	
	delta_p1 = $"Control/VBoxContainer/Hbox-p1/Delta"
	delta_p2 = $"Control/VBoxContainer/Hbox-p2/Delta"
	delta_p3 = $"Control/VBoxContainer/Hbox-p3/Delta"
	delta_p4 = $"Control/VBoxContainer/Hbox-p4/Delta"
	delta_p5 = $"Control/VBoxContainer/Hbox-p5/Delta"
	delta_p6 = $"Control/VBoxContainer/Hbox-p6/Delta"

	slap_p1 = $"Control/VBoxContainer/Hbox-p1/Sector _ Lap"
	slap_p2 = $"Control/VBoxContainer/Hbox-p2/Sector _ Lap"
	slap_p3 = $"Control/VBoxContainer/Hbox-p3/Sector _ Lap"
	slap_p4 = $"Control/VBoxContainer/Hbox-p4/Sector _ Lap"
	slap_p5 = $"Control/VBoxContainer/Hbox-p5/Sector _ Lap"
	slap_p6 = $"Control/VBoxContainer/Hbox-p6/Sector _ Lap"

	prog_p1 = $"Control/VBoxContainer/ProgressBar-p1"
	prog_p2 = $"Control/VBoxContainer/ProgressBar-p2"
	prog_p3 = $"Control/VBoxContainer/ProgressBar-p3"
	prog_p4 = $"Control/VBoxContainer/ProgressBar-p4"
	prog_p5 = $"Control/VBoxContainer/ProgressBar-p5"
	prog_p6 = $"Control/VBoxContainer/ProgressBar-p6"
	
	p1_list = [name_p1, slap_p1, gate_p1, delta_p1, prog_p1]
	p2_list = [name_p2, slap_p2, gate_p2, delta_p2, prog_p2]
	p3_list = [name_p3, slap_p3, gate_p3, delta_p3, prog_p3]
	p4_list = [name_p4, slap_p4, gate_p4, delta_p4, prog_p4]
	p5_list = [name_p5, slap_p5, gate_p5, delta_p5, prog_p5]
	p6_list = [name_p6, slap_p6, gate_p6, delta_p6, prog_p6]
	
	display_list = [p1_list, p2_list, p3_list, p4_list, p5_list, p6_list]
	
	bg_rect = $ColorRect


func _process(delta):
	if ip_complete:
		
		ws.poll()
		
		var state = ws.get_ready_state()
		
		if state == WebSocketPeer.STATE_OPEN:
			while ws.get_available_packet_count() > 0:
				var packet = ws.get_packet()
				var packet_string = packet.get_string_from_utf8()
				var json = JSON.new()
				var pilotdata = json.parse_string(packet_string)  # Correct method to parse JSON string
				
				if "racestatus" in pilotdata:
					#print(pilotdata["racestatus"]["raceAction"])
					if pilotdata["racestatus"]["raceAction"] == "start":
						heatData = {}
						pilots = []
						reset_leaderboard()
						
				elif "racetype" in pilotdata:
					pass  # Handle racetype data
				if "racedata" in pilotdata:
					for pilot_name in pilotdata["racedata"]:
						_on_new_pilot_data_received(pilotdata["racedata"][pilot_name], pilot_name)

		elif state == WebSocketPeer.STATE_CLOSING:
			# Keep polling to achieve proper close.
			pass

		elif state == WebSocketPeer.STATE_CLOSED:
			var code = ws.get_close_code()
			var reason = ws.get_close_reason()
			print("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
			set_process(false) # Stop processing.


func update_pilot_data(new_data, pilotname):
		# new_data is a dictionary like the one you provided
		for pilot_name in new_data.keys():
			var found = false
			for pilot in pilots:
				if pilot["name"] == pilotname:
				# Update existing pilot data
					if new_data["gate"] != pilot["data"]["gate"]:
						var lap = str(new_data["lap"])
						var gate = str(new_data["gate"])
						var lap_gate_key = lap+gate
						pilot["gate_dict"][lap_gate_key] = float(new_data["time"])
						pilot["gate_key"] = lap_gate_key
					pilot["data"] = new_data
					
					found = true
					#print(pilot["gate_list"])
					#var gate_details = [int(pilot["data"]["lap"]), int(pilot["data"]["gate"]), float(pilot["data"]["time"]]
					break
			if not found:
				# Add new pilot
				var lap = str(new_data["lap"])
				var gate = str(new_data["gate"])
				var lap_gate_key = lap+gate
				var gd = {lap_gate_key: float(new_data["time"])}
				pilots.append({"name": pilotname, "data": new_data, "gate_dict": gd, "gate_key": lap_gate_key})


func sort_pilots():
	pilots.sort_custom(func(a, b):
		var lap_a = int(a["data"]["position"])
		var lap_b = int(b["data"]["position"])
		return lap_a < lap_b
	)


func _on_new_pilot_data_received(new_data, pilotname):
	update_pilot_data(new_data, pilotname)
	sort_pilots()
	make_leaderboard()


func make_leaderboard():
	var index = 0
	
	for pilot in pilots:
		if index > 6:
			break
		var hex_color = pilot["data"]["colour"]
		var color = Color("#" + hex_color)
		display_list[index][0].text = pilot["name"]
		display_list[index][0].modulate = color
		display_list[index][1].text = pilot["data"]["lap"]
		display_list[index][2].text = pilot["data"]["gate"]
		display_list[index][4].modulate = color
		display_list[index][4].value = len(pilot["gate_dict"].keys())
		
		if index != 0:
			if pilot["gate_key"] in pilots[index - 1]["gate_dict"]:
				var leader_time = pilots[index - 1]["gate_dict"][pilot["gate_key"]]
				var pilot_time = pilot["gate_dict"][pilot["gate_key"]]
				if pilot["data"]["finished"] == "True":
					display_list[index][3].text = str(pilot["data"]["time"])
				else:
					display_list[index][3].text = str(leader_time - pilot_time)
				
		else:
			if pilot["data"]["finished"] == "True":
				display_list[index][3].text = str(pilot["data"]["time"])
			else:
				display_list[index][3].text = "0.000"
		index += 1


func reset_leaderboard():
	for display in display_list:
		var count = 0
		for each in display:
			if count < 4:
				each.text = "---"
				each.modulate = Color(Color.WHITE)
			else:
				each.value = 0
				each.modulate = Color(Color.WHITE)
			count += 1


func _on_Button_pressed():
	var ip_input = $Control/IP_Input.text
	var url = "ws://%s:60003/velocidrone" % ip_input
	ws.connect_to_url(url)
	print("Attempting to connect to WebSocket server at " + url)
	ip_complete = true
	gate_count = int($"Control/Gate Count".text)
	for each in display_list:
		each[4].min_value = 0
		each[4].max_value = gate_count * 3


func _on_timer_timeout():
	ws.send_text("heartbeat")


func _on_check_button_toggled(toggled_on):
	print(toggled_on)
	if toggled_on:
		bg_rect.color = Color(Color.GREEN)
	else:
		bg_rect.color = Color(Color.BLACK)

extends Node

var ws = WebSocketPeer.new()

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
var connect_button = ""
var connected = false
var single_lap_display = false
var first_place_celebration = ""
var unbursted = true
var last_message = {}
var team_mode = false
var score_a = ""
var score_b = ""
var score_board = {}
var new_score = true
var team_order = []
var race_laps = 3


func _ready():
	
	Engine.max_fps = 30
	
	var ip_addresses = IP.get_local_addresses()
	var ip_input = $Control/IP_Input
	ip_input.text = ip_addresses[-1]

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
	
	first_place_celebration = $Control/Orb
	
	bg_rect = $ColorRect
	
	connect_button = $"Control/Connect Button"
	
	score_a = $"Control/ScoreContainer/Score A"
	score_b = $"Control/ScoreContainer/Score B"


func _process(delta):
	if ip_complete:
		ws.poll()
		var state = ws.get_ready_state()
		match state:
			WebSocketPeer.STATE_OPEN:
				if !connected:
					connect_button.text = "Connected"
					connected = true
				_handle_websocket_messages()
			WebSocketPeer.STATE_CLOSING, WebSocketPeer.STATE_CLOSED:
				if state == WebSocketPeer.STATE_CLOSED:
					_handle_websocket_closed()


func _handle_websocket_messages():
	while ws.get_available_packet_count() > 0:
		var packet = ws.get_packet()
		var packet_string = packet.get_string_from_utf8()
		var json = JSON.new()
		var pilotdata = json.parse_string(packet_string)
		print(pilotdata)
		if pilotdata == last_message:
			return
		last_message = pilotdata
		_process_message(pilotdata)


func _handle_websocket_closed():
	var code = ws.get_close_code()
	var reason = ws.get_close_reason()
	print("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
	set_process(false)  # Optionally stop processing if the WebSocket is closed
	# Reset connected state and UI
	connected = false
	connect_button.text = "Connect"
	reset_leaderboard()


func _process_message(pilotdata):
	if "racestatus" in pilotdata:
		if pilotdata["racestatus"]["raceAction"] == "start":
			heatData = {}
			pilots = []
			reset_leaderboard()
	elif "racetype" in pilotdata:
		if pilotdata["racetype"]["raceLaps"] != str(race_laps):
			race_laps = str(pilotdata["racetype"]["raceLaps"])
	elif "racedata" in pilotdata:
		for pilot_name in pilotdata["racedata"]:
			_on_new_pilot_data_received(pilotdata["racedata"][pilot_name], pilot_name)


func _on_timer_timeout():
	if ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		ws.send_text("heartbeat")


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
	#var start_time = Time.get_ticks_msec()
	update_pilot_data(new_data, pilotname)
	sort_pilots()
	make_leaderboard()
	if team_mode:
		make_scoreboard(team_scores())  # this is where we can call a function to calculate the team scores
	#var end_time = Time.get_ticks_msec()
	#var duration = end_time - start_time
	#print(duration)

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
		if single_lap_display:
			display_list[index][4].value = len(pilot["gate_dict"].keys()) % gate_count
		else:
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
				if unbursted:
					first_place_celebration.burst()
					unbursted = false
			else:
				display_list[index][3].text = "0.000"
		index += 1


# this function is used to keep the team scores from changing order
func initialize_scoreboard(scores):
	team_order = scores.keys()
	for team in team_order:
		score_board[team] = 0
	new_score = false


func team_scores():
	var score_dict = {}
	for pilot in pilots:
		if pilot["data"]["colour"] not in score_dict:
			score_dict[pilot["data"]["colour"]] = [int(pilot["data"]["position"])]
		else:
			score_dict[pilot["data"]["colour"]].append(int(pilot["data"]["position"]))
	return score_dict


func make_scoreboard(scores):
	if len(scores.keys()) == 2:
		if new_score:
			initialize_scoreboard(scores)
		for key in scores.keys():
			var team_total = 0
			for point in scores[key]:
				team_total += point
			score_board[key] = team_total
		
		score_a.text = str(score_board[team_order[0]])
		var hex_color = team_order[0]
		var color = Color("#" + hex_color)
		score_a.modulate = color
		score_b.text = str(score_board[team_order[1]])
		hex_color = team_order[1]
		color = Color("#" + hex_color)
		score_b.modulate = color
	else:
		score_a.text = "-"
		score_b.text = "-"
		score_a.modulate = Color(Color.WHITE)
		score_b.modulate = Color(Color.WHITE)
		

func reset_leaderboard():
	unbursted = true
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
	score_board = {}
	new_score = true
	team_order = []
	score_a.text = "-"
	score_b.text = "-"
	score_a.modulate = Color(Color.WHITE)
	score_b.modulate = Color(Color.WHITE)


func _on_Button_pressed():
	var ip_input = $Control/IP_Input.text
	var url = "ws://%s:60003/velocidrone" % ip_input
	ws.connect_to_url(url)
	print("Attempting to connect to WebSocket server at " + url)
	ip_complete = true
	gate_count = int($"Control/Gate Count".text)
	for each in display_list:
		each[4].min_value = 0
		each[4].max_value = gate_count * race_laps


func _on_Barmode_toggle_pressed(toggled_on):
	if toggled_on:
		for each in display_list:
			each[4].max_value = gate_count
		single_lap_display = true
	else:
		for each in display_list:
			each[4].max_value = gate_count * 3
		single_lap_display = false
		


func _on_TeamvsTeam_toggle_pressed(toggled_on):
	var score_container = $Control/ScoreContainer
	if toggled_on:
		team_mode = true
		score_container.visible = true
	else:
		team_mode = false
		score_container.visible = false


func _on_check_button_toggled(toggled_on):
	if toggled_on:
		bg_rect.color = Color(Color.GREEN)
	else:
		bg_rect.color = Color(Color.BLACK)


func _on_disconnect_pressed():
	ws.close()
	ws = WebSocketPeer.new()
	
	ip_complete = false
	connected = false
	connect_button.text = "Connect"
	
	reset_leaderboard()
	

extends Node

var ws = WebSocketPeer.new()

var pilots = []

@onready var bg_rect = $ColorRect
@onready var connect_button = $"Control/Options/Connect Button"
@onready var dc_button = $"Control/Options/DC Button"
@onready var time_container = $Control/ScrollContainer/TimingContainer
@onready var ip_dropdown = $Control/Options/ip_dropdown
@onready var ip_input = $Control/Options/IP_Input
@onready var score_container = $Control/ScoreContainer
@onready var con_highlighter = $ContenderHighlighter
@onready var pic_viewer = $SubViewport



var ip_complete = false
var connected = false
var single_lap_display = false
var last_message = {}
var team_mode = false
var score_board = {}
var new_score = true
var team_order = []
var score_dict = {}
var point_mode = true
var contender_mode = false
var gap_delta = 0

var timing_row = preload("res://TimingRow.tscn")

var score_box = preload("res://ScoreBox.tscn")

#fall back default values
var gate_count = 30
var race_laps = 3

var FPS = 10



func _ready():
	Engine.max_fps = FPS
	var mac = false
	
	var ip_addresses = IP.get_local_addresses()
	
	if OS.get_name() == "macOS":
		mac = true
	
	for each in ip_addresses:	
		if len(str(each)) <= 17:
			if str(each)[0] != "0":
				if str(each).substr(0, 3) != "169" and str(each).substr(0, 3) != "127":
					ip_dropdown.add_item(str(each))
	if mac:
		ip_dropdown.select(ip_dropdown.item_count - 2)
		ip_input.text = ip_dropdown.get_item_text(ip_dropdown.item_count - 2)
	else:
		ip_input.text = ip_dropdown.get_item_text(ip_dropdown.item_count - 2)
		ip_dropdown.select(ip_dropdown.item_count - 2)
	
	$HeartbeatTimer.start()
	$"Polling Timer".start()


func _process(delta):
	if ip_complete:
		#ws.poll()
		var state = ws.get_ready_state()
		match state:
			WebSocketPeer.STATE_OPEN:
				if !connected:
					connect_button.text = "Connected"
					connected = true
					connect_button.visible = false
					dc_button.visible = true
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
	ip_complete = false


func _process_message(pilotdata):
	print(pilotdata)
	if "racestatus" in pilotdata:
		if pilotdata["racestatus"]["raceAction"] == "start":
			pilots = []
			reset_leaderboard()
	elif "racetype" in pilotdata:
		if pilotdata["racetype"]["raceLaps"] != str(race_laps):
			race_laps = int(pilotdata["racetype"]["raceLaps"])
	elif "racedata" in pilotdata:
		for pilot_name in pilotdata["racedata"]:
			_on_new_pilot_data_received(pilotdata["racedata"][pilot_name], pilot_name)


func check_max_gates(gate):
	if gate > gate_count:
		gate_count = gate
		$"Control/Options/Gate Count".text = str(gate_count)


func _on_timer_timeout():
	if ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		ws.send_text("heartbeat")


func update_pilot_data(new_data, pilotname):
	for pilot_name in new_data.keys():
		var found = false
		for pilot in pilots:
			if pilot["name"] == pilotname:
			# Update existing pilot data
				if new_data["gate"] != pilot["data"]["gate"]:
					var lap = str(new_data["lap"])
					var gate = str(new_data["gate"])
					check_max_gates(int(gate))
					var lap_gate_key = lap+gate
					pilot["gate_dict"][lap_gate_key] = float(new_data["time"])
					pilot["gate_key"] = lap_gate_key
				pilot["data"] = new_data
				found = true
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
	if team_mode: # This is where we can call a function to calculate the team scores
		make_scoreboard()  


func add_timing_row():  #instantiates the timing row scene into the timing display
	var timing_row_instance = timing_row.instantiate()
	time_container.add_child(timing_row_instance)
	timing_row_instance.set_progress_range(0, gate_count * race_laps)


func make_leaderboard():
	var index = 0
	# add rows to the timing display based on the number of pilots
	if len(pilots) > time_container.get_child_count():
		for i in pilots:
			add_timing_row()
			if len(pilots) == time_container.get_child_count():
				break
	if len(pilots) > 1: # this section is for settings the gap of the field
		var last_place = pilots[-1]["gate_dict"][pilots[-1]["gate_key"]]
		if pilots[-1]["gate_key"] in pilots[0]["gate_dict"]:
			var leader = pilots[0]["gate_dict"][pilots[-1]["gate_key"]]
			gap_delta = leader - last_place
			$Control/Options/FieldGap.text = str(gap_delta)
	# set all of the values for the timing display
	if time_container.get_child_count() > 0:
		for pilot in pilots:
			if index > time_container.get_child_count():
				# $Control/Options/FieldGap.text = str(gap_delta)
				break
			var hex_color = pilot["data"]["colour"]
			var color = Color("#" + hex_color)
			var current_pos = time_container.get_children()[index]
					
			current_pos.set_pilot_name(pilot["name"], color)
			current_pos.set_lap(pilot["data"]["lap"])
			current_pos.set_gate(pilot["data"]["gate"])
			current_pos.set_hex_color(hex_color)
			var lap_mod = 0
			if single_lap_display:  # adjusts the lap progress bar
				current_pos.set_progress_range(0, gate_count)
				current_pos.set_progress(int(pilot["data"]["gate"]) % gate_count, color)
				# current_pos.set_progress(len(pilot["gate_dict"].keys()) % gate_count, color)
			else:
				current_pos.set_progress_range(0, gate_count * race_laps)
				if int(pilot["data"]["lap"]) == 3:
					lap_mod = gate_count * 2
				elif int(pilot["data"]["lap"]) == 2:
					lap_mod = gate_count
				else:
					lap_mod = 0
				current_pos.set_progress(int(pilot["data"]["gate"]) + lap_mod, color)
				
			
			if index != 0:   # Calculate deltas if pilots are not in first place.
				if pilot["gate_key"] in pilots[index - 1]["gate_dict"]:
					var leader_time = pilots[index - 1]["gate_dict"][pilot["gate_key"]]
					var pilot_time = pilot["gate_dict"][pilot["gate_key"]]
					if pilot["data"]["finished"] == "True":
						current_pos.set_delta(pilot["data"]["time"])
						current_pos.trigger_burst()
					else:
						current_pos.set_delta(leader_time - pilot_time)			
						# $Control/Options/FieldGap.text = str(gap_delta)
			else:    
				if contender_mode:
					if hex_color == "00FF00": # highlights contender
						con_highlighter.visible = true
					else:
						con_highlighter.visible = false
				
				if pilot["data"]["finished"] == "True":  # Sets the delta for first player
					current_pos.set_delta(pilot["data"]["time"])
					if pilot["data"]["position"] == "1":
						current_pos.trigger_burst()
						current_pos.first_place_burst()
				else:
					current_pos.set_delta(0.000)
			# gap_delta += current_pos.get_delta()
			index += 1

# this function is used to keep the team scores from changing order
func initialize_scoreboard(scores):
	team_order = scores.keys()
	for team in team_order:
		score_board[team] = 0
	new_score = false


func team_scores():
	score_dict = {}
	for pilot in pilots:
		if pilot["data"]["colour"] not in score_dict:
			score_dict[pilot["data"]["colour"]] = [int(pilot["data"]["position"])]
		else:
			score_dict[pilot["data"]["colour"]].append(int(pilot["data"]["position"]))


func add_score_box():  #instantiates the timing row scene into the timing display
	var score_box_instance = score_box.instantiate()
	score_container.add_child(score_box_instance)


func make_scoreboard():
	team_scores()
	var scores = score_dict
	if len(scores.keys()) > score_container.get_child_count():
		for i in scores.keys():
			add_score_box()
			if len(scores.keys()) == score_container.get_child_count():
				break
		new_score = true

	if new_score:
		initialize_scoreboard(scores)
	
	for key in scores.keys():
		var team_total = 0
		score_board[key] = 0
		if point_mode:
			for point in scores[key]:
				var score_result = 7 - point
				if score_result > 0:
					team_total += score_result
			score_board[key] = team_total
		else:
			for point in scores[key]:
				team_total += point
			score_board[key] = team_total
	
	var index = 0
	for each in team_order:
		if score_container.get_child_count() == index:
			break
		var hex_color = each
		var color = Color("#" + hex_color)
		score_container.get_children()[index].set_score(score_board[each])
		score_container.get_children()[index].set_color(color)
		score_container.get_children()[index].update_logo("#" + hex_color)
		index += 1


func reset_leaderboard():
	for child in time_container.get_children():
		time_container.remove_child(child)
		child.queue_free()
	
	pilots = []
	score_board = {}
	new_score = true
	team_order = []
	score_dict = {}
	last_message = {} # this is to prevent reset from clearing results... untested
	reset_gate_count()
	
	if team_mode:
		for child in score_container.get_children():
			score_container.remove_child(child)
			child.queue_free()


func reset_gate_count():
	if int($"Control/Options//Gate Count".text) < 1:
		gate_count = 4
	else:
		gate_count = int($"Control/Options/Gate Count".text)


func _on_Button_pressed():
	var url = "ws://%s:60003/velocidrone" % ip_input.text
	var connect_error = ws.connect_to_url(url)
	if not connect_error:
		print("Attempting to connect to WebSocket server at " + url)
		ip_complete = true
		reset_gate_count()
	else:
		print("connection failed with " + str(connect_error))
		ws.close()
		ws = WebSocketPeer.new()
		ip_complete = false
		connected = false
		connect_button.text = "Connect"
		dc_button.visible = false
		connect_button.visible = true


func _on_Barmode_toggle_pressed(toggled_on):
	if toggled_on:
		single_lap_display = true
		if time_container.get_child_count() > 0:
			for child in time_container.get_children():
				child.set_progress_range(0, gate_count)
				child.toggle_wittness(false)
	else:
		single_lap_display = false
		if time_container.get_child_count() > 0:
			for child in time_container.get_children():
				child.set_progress_range(0, gate_count * race_laps)
				child.toggle_wittness(true)


func _on_TeamvsTeam_toggle_pressed(toggled_on):
	if toggled_on:
		team_mode = true
		score_container.visible = true
		$Control/Options/Pointmode.visible = true
	else:
		team_mode = false
		score_container.visible = false
		$Control/Options/Pointmode.visible = false


func _on_check_button_toggled(toggled_on):
	if toggled_on:
		bg_rect.visible = false
	else:
		bg_rect.visible = true


func _on_disconnect_pressed():
	ws.close()
	ws = WebSocketPeer.new()
	
	ip_complete = false
	connected = false
	connect_button.text = "Connect"
	dc_button.visible = false
	connect_button.visible = true
	reset_leaderboard()


func _on_pointmode_toggled(toggled_on):
	if toggled_on:
		point_mode = true
	else:
		point_mode = false


func _on_copy_to_clipboard_button_pressed():
	if time_container.get_child_count() > 0:
		var copy_string = ""  # TSV header with tabs
		for child in time_container.get_children():
			var pilot_name = child.get_pilot_name()
			var time = child.get_pilot_time()
			var color_out = "#" + child.get_hex_color()
			copy_string += "%s\t%s\t%s\n" % [pilot_name, time, color_out]
		DisplayServer.clipboard_set(copy_string)
		$Control/Options/CopyToClipboardButton.text = "Copied!"
	else:
		$Control/Options/CopyToClipboardButton.text = "No Data"
	$"Text Renamer".start()


func _on_text_renamer_timeout():
	$Control/Options/CopyToClipboardButton.text = "Copy Result"


func _on_menu_button_pressed():
	ws.close()
	get_tree().change_scene_to_file("res://Menu.tscn")


func _on_polling_timer_timeout():
	ws.poll()


func _on_ip_dropdown_item_selected(index):
	ip_input.text = ip_dropdown.get_item_text(index)


func _on_fps_mode_toggled(toggled_on):
	if toggled_on:
		FPS = 60
		Engine.max_fps = FPS
	else:
		FPS = 10
		Engine.max_fps = FPS


func _on_contendermode_toggled(toggled_on):
	contender_mode = toggled_on
	if not toggled_on:
		con_highlighter.visible = false

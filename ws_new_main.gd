extends Node

var ws = WebSocketPeer.new()

var pilots = []

@onready var bg_rect = $ColorRect
@onready var connect_button = $"Control/Connect Button"
@onready var first_place_celebration = $Control/Orb

var ip_complete = false
var connected = false
var single_lap_display = false
var unbursted = true
var last_message = {}
var team_mode = false
var score_board = {}
var new_score = true
var team_order = []
var score_dict = {}
var point_mode = false

var timing_row = preload("res://TimingRow.tscn")

var score_box = preload("res://ScoreBox.tscn")

#fall back default values
var gate_count = 30
var race_laps = 3

var FPS = 60

func _ready():
	Engine.max_fps = FPS
	
	var ip_addresses = IP.get_local_addresses()
	var ip_input = $Control/IP_Input
	ip_input.text = ip_addresses[-1]
	
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
				_handle_websocket_messages()
			WebSocketPeer.STATE_CLOSING, WebSocketPeer.STATE_CLOSED:
				if state == WebSocketPeer.STATE_CLOSED:
					_handle_websocket_closed()

#func _on_data_received():
	#var data= ws.getpacket()
	


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


func _process_message(pilotdata):
	# print(pilotdata)
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
	var timing_container = $Control/TimingContainer
	$Control/TimingContainer.add_child(timing_row_instance)
	timing_row_instance.set_progress_range(0, gate_count * race_laps)


func make_leaderboard():
	var index = 0
	# add rows to the timing display based on the number of pilots
	if len(pilots) > $Control/TimingContainer.get_child_count():
		for i in pilots:
			add_timing_row()
			if len(pilots) == $Control/TimingContainer.get_child_count():
				break
	# set all of the values for the timing display
	if $Control/TimingContainer.get_child_count() > 0:
		for pilot in pilots:
			if index > $Control/TimingContainer.get_child_count():
				break
			var hex_color = pilot["data"]["colour"]
			var color = Color("#" + hex_color)
			var current_pos = $Control/TimingContainer.get_children()[index]
			current_pos.set_pilot_name(pilot["name"], color)
			current_pos.set_lap(pilot["data"]["lap"])
			current_pos.set_gate(pilot["data"]["gate"])
			
			if single_lap_display:  # adjusts the lap progress bar
				current_pos.set_progress_range(0, gate_count)
				current_pos.set_progress(len(pilot["gate_dict"].keys()) % gate_count, color)
			else:
				current_pos.set_progress_range(0, gate_count * race_laps)
				current_pos.set_progress(len(pilot["gate_dict"].keys()), color)
			
			if index != 0:   # Calculate deltas if pilots are not in first place.
				if pilot["gate_key"] in pilots[index - 1]["gate_dict"]:
					var leader_time = pilots[index - 1]["gate_dict"][pilot["gate_key"]]
					var pilot_time = pilot["gate_dict"][pilot["gate_key"]]
					if pilot["data"]["finished"] == "True":
						current_pos.set_delta(pilot["data"]["time"])
						current_pos.trigger_burst()
					else:
						current_pos.set_delta(leader_time - pilot_time)
			
			else:    # Sets the delta for first player
				if pilot["data"]["finished"] == "True":
					current_pos.set_delta(pilot["data"]["time"])
					if unbursted:
						first_place_celebration.burst()
						current_pos.trigger_burst()
						unbursted = false
				else:
					current_pos.set_delta(0.000)
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
	var score_container = $Control/ScoreContainer
	$Control/ScoreContainer.add_child(score_box_instance)


func make_scoreboard():
	team_scores()
	var scores = score_dict
	if len(scores.keys()) > $Control/ScoreContainer.get_child_count():
		for i in scores.keys():
			add_score_box()
			if len(scores.keys()) == $Control/ScoreContainer.get_child_count():
				break
		new_score = true

	if new_score:
		initialize_scoreboard(scores)
	
	for key in scores.keys():
		var team_total = 0
		score_board[key] = 0
		if point_mode:
			for point in scores[key]:
				team_total += 7 - point
			score_board[key] = team_total
		else:
			for point in scores[key]:
				team_total += point
			score_board[key] = team_total
	
	var index = 0
	for each in team_order:
		if $Control/ScoreContainer.get_child_count() == index:
			break
		var hex_color = each
		var color = Color("#" + hex_color)
		$Control/ScoreContainer.get_children()[index].set_score(score_board[each])
		$Control/ScoreContainer.get_children()[index].set_color(color)
		index += 1


func reset_leaderboard():
	unbursted = true
	for child in $Control/TimingContainer.get_children():
		$Control/TimingContainer.remove_child(child)
		child.queue_free()
	pilots = []
	score_board = {}
	new_score = true
	team_order = []
	
	# this section is new to the reset might cause issues
	last_message = {}
	score_dict = {}
	
	if team_mode:
		for child in $Control/ScoreContainer.get_children():
			$Control/ScoreContainer.remove_child(child)
			child.queue_free()


func _on_Button_pressed():
	var ip_input = $Control/IP_Input.text
	var url = "ws://%s:60003/velocidrone" % ip_input
	ws.connect_to_url(url)
	print("Attempting to connect to WebSocket server at " + url)
	ip_complete = true
	gate_count = int($"Control/Gate Count".text)


func _on_Barmode_toggle_pressed(toggled_on):
	if toggled_on:
		single_lap_display = true
		if $Control/TimingContainer.get_child_count() > 0:
			for child in $Control/TimingContainer.get_children():
				child.set_progress_range(0, gate_count)
	else:
		single_lap_display = false
		if $Control/TimingContainer.get_child_count() > 0:
			for child in $Control/TimingContainer.get_children():
				child.set_progress_range(0, gate_count * race_laps)


func _on_TeamvsTeam_toggle_pressed(toggled_on):
	var score_container = $Control/ScoreContainer
	if toggled_on:
		team_mode = true
		score_container.visible = true
		$Control/Pointmode.visible = true
	else:
		team_mode = false
		score_container.visible = false
		$Control/Pointmode.visible = false


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


func _on_pointmode_toggled(toggled_on):
	if toggled_on:
		point_mode = true
	else:
		point_mode = false


func _on_copy_to_clipboard_button_pressed():
	if $Control/TimingContainer.get_child_count() > 0:
		var copy_string = ""  # TSV header with tabs
		for child in $Control/TimingContainer.get_children():
			var pilot_name = child.get_pilot_name()
			var time = child.get_pilot_time()
			copy_string += "%s\t%s\n" % [pilot_name, time]
		DisplayServer.clipboard_set(copy_string)
		$Control/CopyToClipboardButton.text = "Copied!"
	else:
		$Control/CopyToClipboardButton.text = "No Data"
	$"Text Renamer".start()


func _on_text_renamer_timeout():
	$Control/CopyToClipboardButton.text = "Copy Result"


func _on_polling_timer_timeout():
	ws.poll()

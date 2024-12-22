extends Node

var ws = WebSocketPeer.new()

var pilots = []

var lap_log = []

var gate_dict = {}

@onready var bg_rect = $ColorRect
@onready var connect_button = $"Control/Connect Button"
@onready var first_place_celebration = $Control/Orb
@onready var timing_row = $"Control/Sector Timing"
@onready var lap_container = $Control/TimingContainer

var lap_row = preload("res://SectorRow.tscn")

var ip_complete = false
var connected = false
var last_message = {}


#fall back default values
var gate_count = 30
var race_laps = 3
var sector_1_start = 10
var sector_2_start = 20
var sector_3_start = 30

var FPS = 60

var blap_color = Color(0, 1, 0)
var lap_color = Color(1, 1, 1)

var single_lap_best = 10000.0


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
	# reset_leaderboard()


func _process_message(pilotdata):
	# print(pilotdata)
	if "racestatus" in pilotdata:
		if pilotdata["racestatus"]["raceAction"] == "start":
			reset()
	elif "racetype" in pilotdata:
		if pilotdata["racetype"]["raceLaps"] != str(race_laps):
			race_laps = int(pilotdata["racetype"]["raceLaps"])
	elif "racedata" in pilotdata:
		update_times(pilotdata["racedata"])


func _on_timer_timeout():
	if ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		ws.send_text("heartbeat")


func update_times(racedata):
	#var hex_color = pilot["data"]["colour"]
	#var color = Color("#" + hex_color)
	#timing_row.set_pilot_name(pilot["name"], color)
	var pilot_name = racedata.keys()[0]
	#timing_row.set_pilot_name(pilot_name, racedata[pilot_name]["data"]["colour"])
	
	var current_gate = int(racedata[pilot_name]["gate"])
	
	var current_lap = int(racedata[pilot_name]["lap"])
	
	var current_time = float(racedata[pilot_name]["time"])
	
	lap_log.append([pilot_name, current_lap, current_gate, current_time])
	
	gate_dict[current_gate] = current_time
	
	update_sector()
	


func update_sector():
	if len(lap_log) != 0:
		var recent_update = lap_log[-1]
	
		var gate = recent_update[2]
		var lap = recent_update[1]
		var time = recent_update[3]
		var best_lap = false
		var starting_gate = 1
		if gate_dict.has(starting_gate):
			# print(gate_dict[starting_gate])
			if gate == sector_1_start:
				var split = "err"
				if gate_dict.has(starting_gate):
					split = time - gate_dict[starting_gate]
				best_lap = timing_row.set_s1(split)
			elif gate == sector_2_start:
				var split = time - gate_dict[sector_1_start] 
				best_lap = timing_row.set_s2(split)
			elif gate == sector_3_start:
				var split = time - gate_dict[sector_2_start] 
				best_lap = timing_row.set_s3(split)
				timing_row.set_total()
		else:
			print("starting gate missing from dictionary")
		
		update_lap_history(best_lap)


func update_lap_history(best_lap):
	# print(best_lap)
	var recent_update = lap_log[-1]
	var gate = recent_update[2]
	var lap = recent_update[1]
	var time = recent_update[3]
	var starting_gate = 1
	# var current_lap_row = lap_row_1
	
	while $Control/TimingContainer.get_child_count() < lap:
		add_lap_row()
	#if $Control/TimingContainer.get_child_count() < lap:
	#	add_lap_row()
	
	var current_lap_row = $Control/TimingContainer.get_children()[lap - 1]
	
	current_lap_row.set_row_name("Lap " + str(lap))
	#if lap == 1:
	#	current_lap_row = lap_row_1
	#elif lap == 2:
	#	current_lap_row = lap_row_2
	#elif lap == 3:
	#	current_lap_row = lap_row_3
	
	if gate_dict.has(starting_gate):
		if gate == sector_1_start:
			var split = "err"
			if gate_dict.has(starting_gate):
				split = time - gate_dict[starting_gate] 
				current_lap_row.set_s1(split)
				if best_lap:
					for each in $Control/TimingContainer.get_children():
						each.s1.modulate = lap_color
					current_lap_row.s1.modulate = blap_color
		elif gate == sector_2_start:
			var split = time - gate_dict[sector_1_start] 
			current_lap_row.set_s2(split)
			if best_lap:
				for each in $Control/TimingContainer.get_children():
					each.s2.modulate = lap_color
				current_lap_row.s2.modulate = blap_color
		elif gate == sector_3_start:
			var split = time - gate_dict[sector_2_start] 
			current_lap_row.set_s3(split)
			var total_time = current_lap_row.set_total()
			if total_time < single_lap_best:
				single_lap_best = total_time
				for each in $Control/TimingContainer.get_children():
					each.total.modulate = lap_color
				current_lap_row.total.modulate = blap_color
			if best_lap:
				for each in $Control/TimingContainer.get_children():
					each.s3.modulate = lap_color
				current_lap_row.s3.modulate = blap_color


func _on_Button_pressed():
	var ip_input = $Control/IP_Input.text
	var url = "ws://%s:60003/velocidrone" % ip_input
	ws.connect_to_url(url)
	print("Attempting to connect to WebSocket server at " + url)
	ip_complete = true


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


func add_lap_row():  #instantiates the lap row scene into the timing container
	var lap_row_instance = lap_row.instantiate()
	lap_container.add_child(lap_row_instance)



func _on_copy_to_clipboard_button_pressed():
	var copy_string = ""  # TSV header with tabs
	copy_string += "%s\t%s\t%s\t%s\n" % ["Name", "Lap", "Gate", "Time"]
	if len(lap_log) > 0:
		for lap in lap_log:
			copy_string += "%s\t%s\t%s\t%s\n" % [lap[0], lap[1], lap[2], lap[3]]
		DisplayServer.clipboard_set(copy_string)
		$Control/CopyToClipboardButton.text = "Copied!"
	else:
		$Control/CopyToClipboardButton.text = "No Data"
	$"Text Renamer".start()


func _on_text_renamer_timeout():
	$Control/CopyToClipboardButton.text = "Copy Result"


func apply_sectors():
	sector_1_start = int($"Control/HBoxContainer/Sector Input 1".text)
	sector_2_start = int($"Control/HBoxContainer/Sector Input 2".text)
	sector_3_start = int($"Control/HBoxContainer/Sector Input 3".text)
	# print(sector_1_start, sector_2_start, sector_3_start)


func reset():
	# timing_row.reset()
	lap_log = []
	gate_dict = {}
	timing_row.set_row_name("Best")
	for child in $Control/TimingContainer.get_children():
		$Control/TimingContainer.remove_child(child)
		child.queue_free()


func full_reset():
	timing_row.reset()
	lap_log = []
	gate_dict = {}
	timing_row.set_row_name("Best")
	for child in $Control/TimingContainer.get_children():
		$Control/TimingContainer.remove_child(child)
		child.queue_free()


func _on_menu_button_pressed():
	ws.close()
	get_tree().change_scene_to_file("res://Menu.tscn")


func _on_polling_timer_timeout():
	ws.poll()

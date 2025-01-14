extends Node

# Scene Element Objects
@onready var bg_rect = $ColorRect
@onready var connect_button = $"Control/Options/Connect Button"
@onready var dc_button = $"Control/Options/DC Button"
@onready var timing_row = $"Control/Sector Timing"
@onready var lap_container = $Control/ScrollContainer/TimingContainer
@onready var ip_dropdown = $Control/Options/ip_dropdown
@onready var ip_input = $Control/Options/IP_Input


var lap_row = preload("res://SectorRow.tscn")
var ws = WebSocketPeer.new()

# Global Variables
var lap_log = []
var gate_dict = {}
var ip_complete = false
var connected = false
var last_message = {}

# Fall back default values
var gate_count = 30
var sector_1_start = 10
var sector_2_start = 20
var sector_3_start = 30
var single_lap_best = 10000.0

# Constants
var FPS = 60
var BLAP_COLOR = Color(0, 1, 0)
var LAP_COLOR = Color(1, 1, 1)

# Setup scene
func _ready():
	Engine.max_fps = FPS
	
	var mac = false
	
	var ip_addresses = IP.get_local_addresses()
	ip_input.text = ip_addresses[-1]
	
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


func _process(delta): # Check websocket status
	if ip_complete:
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


func _handle_websocket_messages(): # Convert websocket into json and discard repeat messages
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
	ip_complete = false


func _process_message(pilotdata):
	if "racestatus" in pilotdata:
		if pilotdata["racestatus"]["raceAction"] == "start":
			reset()
	elif "racedata" in pilotdata:
		update_times(pilotdata["racedata"])


func _on_timer_timeout(): # Heartbeat timer to keep websocket open
	if ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		ws.send_text("heartbeat")


func update_times(racedata): # Parse racedata into list to add to lap log
	var pilot_name = racedata.keys()[0]

	var current_gate = int(racedata[pilot_name]["gate"])
	
	var current_lap = int(racedata[pilot_name]["lap"])
	
	var current_time = float(racedata[pilot_name]["time"])
	
	lap_log.append([pilot_name, current_lap, current_gate, current_time])
	
	gate_dict[current_gate] = current_time
	
	update_sector()


func update_sector(): # update best splits and pass if they are best
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


func update_lap_history(best_lap): # Update the current lap splits and highlight them if best of session
	var recent_update = lap_log[-1]
	var gate = recent_update[2]
	var lap = recent_update[1]
	var time = recent_update[3]
	var starting_gate = 1

	while lap_container.get_child_count() < lap:
		add_lap_row()

	var current_lap_row = lap_container.get_children()[lap - 1]
	
	current_lap_row.set_row_name("Lap " + str(lap))
	
	if gate_dict.has(starting_gate):
		if gate == sector_1_start:
			var split = "err"
			if gate_dict.has(starting_gate):
				split = time - gate_dict[starting_gate] 
				current_lap_row.set_s1(split)
				if best_lap:
					for each in lap_container.get_children():
						each.s1.modulate = LAP_COLOR
					current_lap_row.s1.modulate = BLAP_COLOR
		elif gate == sector_2_start:
			var split = time - gate_dict[sector_1_start] 
			current_lap_row.set_s2(split)
			if best_lap:
				for each in lap_container.get_children():
					each.s2.modulate = LAP_COLOR
				current_lap_row.s2.modulate = BLAP_COLOR
		elif gate == sector_3_start:
			var split = time - gate_dict[sector_2_start] 
			current_lap_row.set_s3(split)
			var total_time = current_lap_row.set_total()
			if total_time < single_lap_best:
				single_lap_best = total_time
				for each in lap_container.get_children():
					each.total.modulate = LAP_COLOR
				current_lap_row.total.modulate = BLAP_COLOR
			if best_lap:
				for each in lap_container.get_children():
					each.s3.modulate = LAP_COLOR
				current_lap_row.s3.modulate = BLAP_COLOR


func _on_Button_pressed(): # connect the websocker
	var url = "ws://%s:60003/velocidrone" % $Control/Options/IP_Input.text
	var connect_status = ws.connect_to_url(url)
	if connect_status < 1:
		print("Attempting to connect to WebSocket server at " + url)
		ip_complete = true
	else:
		print("connection failed with " + str(connect_status))
		ws.close()
		ws = WebSocketPeer.new()
		ip_complete = false
		connected = false
		connect_button.text = "Connect"
		dc_button.visible = false
		connect_button.visible = true


func _on_check_button_toggled(toggled_on): # background color change
	if toggled_on:
		bg_rect.visible = false
	else:
		bg_rect.visible = true


func _on_disconnect_pressed(): # close websocket connection
	ws.close()
	ws = WebSocketPeer.new()
	
	ip_complete = false
	connected = false
	connect_button.text = "Connect"
	dc_button.visible = false
	connect_button.visible = true


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
		$Control/Options/CopyToClipboardButton.text = "Copied!"
	else:
		$Control/Options/CopyToClipboardButton.text = "No Data"
	$"Text Renamer".start()


func _on_text_renamer_timeout(): # reset button text
	$Control/Options/CopyToClipboardButton.text = "Copy Result"


func apply_sectors(): # handle the input from the split settings
	sector_1_start = int($"Control/VBoxContainer/Sector_end_gates/Sector Input 1".text)
	sector_2_start = int($"Control/VBoxContainer/Sector_end_gates/Sector Input 2".text)
	sector_3_start = int($"Control/VBoxContainer/Sector_end_gates/Sector Input 3".text)
	# timing_row.set_s1($Control/VBoxContainer/Target_Times/s1_time.text)
	# timing_row.set_s2($Control/VBoxContainer/Target_Times/s2_time.text)
	# timing_row.set_s3($Control/VBoxContainer/Target_Times/s3_time.text)
	# timing_row.set_total()
	
func reset(): # clean up global variables and remove all lap rows
	lap_log = []
	gate_dict = {}
	timing_row.set_row_name("Best")
	for child in lap_container.get_children():
		lap_container.remove_child(child)
		child.queue_free()


func full_reset(): # Same as reset but reset the best splits also.
	timing_row.reset()
	lap_log = []
	gate_dict = {}
	timing_row.set_row_name("Best")
	for child in lap_container.get_children():
		lap_container.remove_child(child)
		child.queue_free()


func _on_menu_button_pressed(): # back to main menu
	ws.close()
	get_tree().change_scene_to_file("res://Menu.tscn")


func _on_polling_timer_timeout(): # handle polling
	ws.poll()


func _on_ip_dropdown_item_selected(index):
	ip_input.text = ip_dropdown.get_item_text(index)


func _on_fps_mode_toggled(toggled_on):
	if toggled_on:
		FPS = 10
		Engine.max_fps = FPS
	else:
		FPS = 60
		Engine.max_fps = FPS
	

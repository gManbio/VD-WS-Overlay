extends Node

var ws = WebSocketPeer.new()

var heartbeat = ""

var heatData = []
var pilot_list = []

func _ready():
	
	var url = "ws://192.168.1.156:60003/velocidrone"
	ws.connect_to_url(url)
	print("Attempting to connect to WebSocket server at " + url)
	
	
func _process(delta):
	ws.poll()
	var state = ws.get_ready_state()

	if state == WebSocketPeer.STATE_OPEN:
		while ws.get_available_packet_count() > 0:
			var packet = ws.get_packet()
			var packet_string = packet.get_string_from_utf8()
			var pilotdata = JSON.parse_string(packet_string)
			print(pilotdata)
			if len(pilotdata.keys()) > 0:
				print(pilotdata.keys())
			if pilotdata.keys()[0] == "racestatus":
				print(pilotdata["racestatus"]["raceAction"])
				if pilotdata["racestatus"]["raceAction"] == "start":
					heatData = []
					pilot_list = []
			elif pilotdata.keys()[0] == "racetype":
				pass
			if pilotdata.keys()[0] == "racedata":
				var pilot = pilotdata["racedata"]
				print(pilot)
				if len(pilot_list) == 0:
					pilot_list.append(pilot.keys()[0])
				print(pilot.keys[0])
				print(pilot_list)
				#if pilot[0]
				
				#for key in pilot:
				#	var value = pilot[key]
				#	print(value)

			
			
			create_pilot(pilotdata)
	
	elif state == WebSocketPeer.STATE_CLOSING:
		# Keep polling to achieve proper close.
		pass
	
	elif state == WebSocketPeer.STATE_CLOSED:
		var code = ws.get_close_code()
		var reason = ws.get_close_reason()
		print("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
		set_process(false) # Stop processing.


func create_pilot(racedata):
	print(racedata)
		# Get the first pilot's name

	#elif racedata["racedata"] != null:
	#	var pilots = racedata["racedata"].keys()
	#	var first_pilot_name = pilots[0]

		# Now that you have the first pilot's name, you can access their data
	#	var first_pilot_data = racedata["racedata"][first_pilot_name]


	pass
	
	
